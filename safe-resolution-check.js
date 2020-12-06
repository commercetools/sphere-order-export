const { spawn } = require( 'child_process' );

try {
    spawn( 'npx', ['npm-force-resolutions']);
} catch(e) {
    console.warn("Failed to detect package-lock.json so npm install is running in fallback mode")
    console.warn(e);
}