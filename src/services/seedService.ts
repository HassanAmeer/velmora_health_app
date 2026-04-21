import {
    collection,
    doc,
    setDoc,
    addDoc,
    getDocs,
    deleteDoc,
    serverTimestamp,
    query,
    Timestamp,
} from 'firebase/firestore';
import { createUserWithEmailAndPassword } from 'firebase/auth';
import { db, auth } from './firebase';
import {
    migrationData,
    type UploadMode,
    type CollectionSeedDefinition,
    type SubcollectionSeedDefinition,
} from '../data/migrationData';

export type SeedMode = 'full' | 'append-users' | 'configs-only';

export const DEFAULT_ADMIN_EMAIL = 'admin@gmail.com';
export const DEFAULT_ADMIN_PASSWORD = '12345678';

const clearCollectionByPath = async (collectionPath: string) => {
    const snap = await getDocs(query(collection(db, collectionPath)));
    const deletes = snap.docs.map((d) => deleteDoc(doc(db, collectionPath, d.id)));
    await Promise.all(deletes);
};

const convertSpecialValues = (value: unknown): unknown => {
    if (Array.isArray(value)) {
        return value.map((item) => convertSpecialValues(item));
    }

    if (value && typeof value === 'object') {
        const asRecord = value as Record<string, unknown>;
        if (
            asRecord.__type === 'Timestamp' &&
            typeof asRecord.seconds === 'number' &&
            typeof asRecord.nanoseconds === 'number'
        ) {
            return new Timestamp(asRecord.seconds, asRecord.nanoseconds);
        }

        const converted: Record<string, unknown> = {};
        Object.entries(asRecord).forEach(([key, nested]) => {
            converted[key] = convertSpecialValues(nested);
        });
        return converted;
    }

    return value;
};

const writeDocument = async (
    collectionPath: string,
    uploadMode: UploadMode,
    entry: { id?: string; data: Record<string, any> }
) => {
    const data = convertSpecialValues(entry.data) as Record<string, any>;

    if (uploadMode === 'add') {
        await addDoc(collection(db, collectionPath), data);
        return;
    }

    if (entry.id) {
        await setDoc(doc(db, collectionPath, entry.id), data, {
            merge: uploadMode === 'merge',
        });
        return;
    }

    await addDoc(collection(db, collectionPath), data);
};

const seedCollection = async (
    definition: CollectionSeedDefinition,
    progressCallback: (msg: string) => void
) => {
    progressCallback(`Seeding ${definition.path}...`);
    for (const entry of definition.documents) {
        await writeDocument(definition.path, definition.uploadMode, entry);
    }
};

const seedSubcollection = async (
    definition: SubcollectionSeedDefinition,
    progressCallback: (msg: string) => void
) => {
    progressCallback(`Seeding users/*/${definition.path}...`);

    for (const [userId, entries] of Object.entries(definition.documentsByUserId)) {
        const collectionPath = `users/${userId}/${definition.path}`;
        for (const entry of entries) {
            await writeDocument(collectionPath, definition.uploadMode, entry);
        }
    }
};

const clearFullDataset = async (progressCallback: (msg: string) => void) => {
    progressCallback('Clearing previous migration data...');

    const collectionsToClear = [
        migrationData.collections.userGames.path,
        migrationData.collections.userGameProgress.path,
        migrationData.collections.gameQuestions.path,
        migrationData.collections.games.path,
        migrationData.collections.subscriptionPlans.path,
        migrationData.collections.faqs.path,
        migrationData.collections.users.path,
    ];

    for (const collectionPath of collectionsToClear) {
        await clearCollectionByPath(collectionPath);
    }

    const userIds = migrationData.collections.users.documents
        .map((entry) => entry.id)
        .filter((id): id is string => Boolean(id));

    const userSubcollections = Object.values(migrationData.userSubcollections);

    for (const userId of userIds) {
        for (const subDefinition of userSubcollections) {
            await clearCollectionByPath(`users/${userId}/${subDefinition.path}`);
        }
    }
};

const runFullMigration = async (progressCallback: (msg: string) => void) => {
    await seedCollection(migrationData.collections.users, progressCallback);

    await seedSubcollection(migrationData.userSubcollections.chatMessages, progressCallback);
    await seedSubcollection(migrationData.userSubcollections.kegelDailyCompletions, progressCallback);
    await seedSubcollection(migrationData.userSubcollections.kegelSessions, progressCallback);
    await seedSubcollection(migrationData.userSubcollections.notifications, progressCallback);

    await seedCollection(migrationData.collections.games, progressCallback);
    await seedCollection(migrationData.collections.gameQuestions, progressCallback);
    await seedCollection(migrationData.collections.userGameProgress, progressCallback);
    await seedCollection(migrationData.collections.userGames, progressCallback);
    await seedCollection(migrationData.collections.subscriptionPlans, progressCallback);
    await seedCollection(migrationData.collections.faqs, progressCallback);

    progressCallback('Seeding singleton documents...');
    for (const singleton of migrationData.singletonDocs) {
        const data = convertSpecialValues(singleton.data) as Record<string, any>;
        const [collectionId, documentId, ...nestedPath] = singleton.pathSegments;
        await setDoc(doc(db, collectionId, documentId, ...nestedPath), data, { merge: true });
    }
};

const runAppendUsers = async (progressCallback: (msg: string) => void) => {
    await seedCollection(migrationData.collections.users, progressCallback);
    await seedSubcollection(migrationData.userSubcollections.chatMessages, progressCallback);
    await seedSubcollection(migrationData.userSubcollections.kegelDailyCompletions, progressCallback);
    await seedSubcollection(migrationData.userSubcollections.kegelSessions, progressCallback);
    await seedSubcollection(migrationData.userSubcollections.notifications, progressCallback);
    await seedCollection(migrationData.collections.userGameProgress, progressCallback);
    await seedCollection(migrationData.collections.userGames, progressCallback);
};

const runConfigsOnly = async (progressCallback: (msg: string) => void) => {
    await seedCollection(migrationData.collections.subscriptionPlans, progressCallback);
    await seedCollection(migrationData.collections.faqs, progressCallback);

    progressCallback('Seeding singleton documents...');
    for (const singleton of migrationData.singletonDocs) {
        const data = convertSpecialValues(singleton.data) as Record<string, any>;
        const [collectionId, documentId, ...nestedPath] = singleton.pathSegments;
        await setDoc(doc(db, collectionId, documentId, ...nestedPath), data, { merge: true });
    }
};

export const seedService = {
    seedAdmin: async () => {
        try {
            const userCredential = await createUserWithEmailAndPassword(
                auth,
                DEFAULT_ADMIN_EMAIL,
                DEFAULT_ADMIN_PASSWORD
            );
            const uid = userCredential.user.uid;

            await setDoc(
                doc(db, 'admin', uid),
                {
                    uid,
                    email: DEFAULT_ADMIN_EMAIL,
                    role: 'Super Admin',
                    createdAt: serverTimestamp(),
                },
                { merge: true }
            );

            return { success: true, message: 'Admin user created successfully.' };
        } catch (error: any) {
            if (error?.code === 'auth/email-already-in-use') {
                const currentUser = auth.currentUser;
                if (currentUser) {
                    await setDoc(
                        doc(db, 'admin', currentUser.uid),
                        {
                            uid: currentUser.uid,
                            email: currentUser.email || DEFAULT_ADMIN_EMAIL,
                            role: 'Super Admin',
                            createdAt: serverTimestamp(),
                        },
                        { merge: true }
                    );
                    return { success: true, message: 'Admin already exists, role ensured.' };
                }

                return {
                    success: true,
                    message: 'Admin already exists in Auth. Log in once to auto-link the admin role document.',
                };
            }

            throw error;
        }
    },

    migrateData: async (mode: SeedMode, progressCallback: (msg: string) => void) => {
        progressCallback('Starting migration...');

        if (mode === 'full') {
            await clearFullDataset(progressCallback);
            await runFullMigration(progressCallback);
        }

        if (mode === 'append-users') {
            await runAppendUsers(progressCallback);
        }

        if (mode === 'configs-only') {
            await runConfigsOnly(progressCallback);
        }

        progressCallback('Migration complete! ✅');
    },

    seedDummyData: async (progressCallback: (msg: string) => void) => {
        await seedService.migrateData('full', progressCallback);
    },
};
