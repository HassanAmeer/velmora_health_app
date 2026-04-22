import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from './firebase';

// This service handles sending FCM notifications directly from the React Admin Panel
// using the FCM HTTP v1 API.

const SERVICE_ACCOUNT = {
    "project_id": "together-wellness",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCpdKLEGXcJIAFm\nSz1IQZbQJe1uQYDFv1b8Dm8dLRWJcfNGAnwZMXM0mU3kUBTtfuGaQaFY5y9bIZ2F\nfQQnCvcxdg5P4/MdcWUEsFnCVRIUjvuqt2wMmJzupl7XJUgu81yIO+Rxv3r7SzCU\naO9eMmSCK+NBAVWI8uKiEFcDmrrYa6XOELfm59vbSqG4jbB+VaxKpMUxne7G1ZSG\nmpuRDmHO6KRcnihXMiiEo/b1oiz0D2m05EcRie3sWFOusRzus/pIcSlduLFIXcQM\nZdYZKXtRvJ3PpEDPQVLK7hAOHREaY0SvVjpIuWiYKQiY6EGoZiwD354TUaVx6Chl\nhvswJSjvAgMBAAECggEAI0vzN2uietka0YbsjedzlYnA6g1k2Evhv4D2Lhqc+NMu\nfC+6T7kYKSWhruPraAjczzfKdu041P+sgwimW8eR89CGbKerlT9wbkiZebwklvmt\nfELWk80aKy+mY6QVZAo3BP2MuRDMehmQVemBqppOizq/DGRNv8fv4xgKN+r77mYv\nB6/ohXfKP99j99qhwDAd9W6OMO57QzQplahazqI4PyaZOjmlXhUfgxUSop0Q7Zk9\n7rUEN74BcSShhdQgcldOVrsQX1RstrWBHgVW1dRCkGBKwbRQP61I5HV5NBw5VmAy\n2+dnFWaQ4jbM2FLwRpLxg1iRYENBonQsOugC8AXDSQKBgQDV3tV6n+3Q7dKLQzSi\nwKSYC1GVWUDODyJsF2rpLXosdtLrTzublpzASpe2nBpeRb9sNUrUpMvcVt/TiEyo\nVX2Di+swi9p53kjEQ9rj4YJMBF3eHh7IGJmzKI0uZSi+Cf9W7l710tU16d6SbXbU\nS21HUTzIGAJth8JWDYCBheMeWwKBgQDK1gc7meXGmOYdouNdsHRVr42hAvop2zXf\nKz6dnFNcrm1xeX/jMN5dXWL9gByHYzPjUeYXvSIdE6jfEfBxZtPYwjxJ5rm0Ahdn\nH1fAqxPG91oTps/dyx+O8uEMFmipNHrvO7z7kgvpdCSioZeijnBn6JZoX1PCNMoD\nC2BcvzrL/QKBgQCOmUo7vcDCap/UbRX+YnYcToeyDdWwztSDv8Vv/fuVBBE0BhtX\nbT/M0q9/eWv3aYftrUbcq5ilrGMG1r1OC9ppSHSjZMxiL3zTJ+8dvDG1X7/6ppid\nkBGDLEmeIqLcuyu+GafFPjMdBHd7qHLvr+8H+zmMrL2JrFg+KjiBo/TAOwKBgQDD\nYVamOp/ypOVENtr8LDRjNS8foVaHaviBd45hE2vZIsuZOofNuAz5sjLgLL9OSmh4\n1zLkOvLZP06zUPxiv8HgUXjxVqYalskkNDS7Cg+K4EiMFWq1IivL7niIxC0cj8i7\nGLf5O7ztq0p+vVjq5HmyHYCEGQ79Swwr0pGHxUxFoQKBgGFJJHNvdTgreaYk53N+\nmTBHv+Yr8+Bp//d/frZYRZ3z81xld4jSAu3XYCxTKVmZSVOaEEi+ZIPtT2KlBgKl\npiVy43RMjqZi/4kqNq1bMCr6XWQ6t0HyC59a81TM6wXajH9IqMr2EFW2t/K1CIEl\nAmIJq243GNTrBjvUGPEfmRFK\n-----END PRIVATE KEY-----\n",
    "client_email": "firebase-adminsdk-fbsvc@together-wellness.iam.gserviceaccount.com",
};

/**
 * Gets an OAuth2 Access Token for FCM v1
 * Note: Signing a JWT in the frontend requires Web Crypto API.
 */
async function getAccessToken() {
    const header = {
        alg: "RS256",
        typ: "JWT",
    };

    const now = Math.floor(Date.now() / 1000);
    const payload = {
        iss: SERVICE_ACCOUNT.client_email,
        sub: SERVICE_ACCOUNT.client_email,
        aud: "https://oauth2.googleapis.com/token",
        iat: now,
        exp: now + 3600,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
    };

    const encodedHeader = btoa(JSON.stringify(header)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
    const encodedPayload = btoa(JSON.stringify(payload)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
    const partialToken = `${encodedHeader}.${encodedPayload}`;

    // Import the private key for signing
    const pemContents = SERVICE_ACCOUNT.private_key
        .replace(/-----BEGIN PRIVATE KEY-----/, "")
        .replace(/-----END PRIVATE KEY-----/, "")
        .replace(/\s/g, "");

    const binaryKey = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0));

    const cryptoKey = await window.crypto.subtle.importKey(
        "pkcs8",
        binaryKey,
        {
            name: "RSASSA-PKCS1-v1_5",
            hash: "SHA-256",
        },
        false,
        ["sign"]
    );

    const signatureBuffer = await window.crypto.subtle.sign(
        "RSASSA-PKCS1-v1_5",
        cryptoKey,
        new TextEncoder().encode(partialToken)
    );

    const signature = btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)))
        .replace(/=/g, "")
        .replace(/\+/g, "-")
        .replace(/\//g, "_");

    const jwt = `${partialToken}.${signature}`;

    // Exchange JWT for Access Token
    const authResponse = await fetch("https://oauth2.googleapis.com/token", {
        method: "POST",
        headers: {
            "Content-Type": "application/x-www-form-urlencoded",
        },
        body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });

    const authData = await authResponse.json();
    if (!authData.access_token) {
        throw new Error(`Authentication failed: ${JSON.stringify(authData)}`);
    }
    return authData.access_token;
}

export const sendFCMNotification = async (params: {
    recipientToken?: string;
    topic?: string;
    title: string;
    body: string;
}) => {
    const { recipientToken, topic, title, body } = params;

    try {
        const accessToken = await getAccessToken();
        const projectId = SERVICE_ACCOUNT.project_id;

        const message: any = {
            notification: {
                title,
                body,
            },
            android: {
                notification: {
                    icon: "ic_notification",
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
            },
        };

        if (topic) {
            message.topic = topic;
        } else if (recipientToken) {
            message.token = recipientToken;
        } else {
            throw new Error("Either recipientToken or topic must be provided");
        }

        const response = await fetch(
            `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${accessToken}`,
                },
                body: JSON.stringify({ message }),
            }
        );

        const result = await response.json();
        console.log("FCM Response:", result);
        return result;
    } catch (e) {
        console.error("FCM Send Error:", e);
        throw e;
    }
};

export const saveNotificationToFirestore = async (uid: string, notification: any) => {
    return addDoc(
        collection(db, 'users', uid, 'notifications'),
        {
            ...notification,
            isRead: false,
            timestamp: serverTimestamp(),
        }
    );
};
