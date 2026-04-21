/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            colors: {
                primary: {
                    light: '#A78BFA',
                    DEFAULT: '#7C3AED',
                    dark: '#5B21B6',
                }
            }
        },
    },
    plugins: [],
}
