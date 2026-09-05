// Génère public/config.js à partir des variables d'environnement Vercel.
// Exécuté automatiquement au déploiement (voir "build" dans package.json).
const fs = require("fs");

const keys = [
  "SUPABASE_URL",
  "SUPABASE_ANON_KEY",
  "FOOTBALL_DATA_API_KEY",
  "COMPETITION_CODE",
  "SITE_BASE_URL",
];

const missing = keys.filter((k) => !process.env[k]);
if (missing.length > 0) {
  console.warn(
    `⚠️  Variable(s) d'environnement manquante(s) sur Vercel : ${missing.join(", ")}. ` +
    `Ajoute-les dans Project Settings > Environment Variables, puis redéploie.`
  );
}

const values = {};
for (const key of keys) values[key] = process.env[key] || "";

const content = `// Fichier généré automatiquement au déploiement à partir des variables\n` +
  `// d'environnement Vercel. Ne pas éditer ni committer ce fichier (voir .gitignore).\n` +
  `window.APP_CONFIG = ${JSON.stringify(values, null, 2)};\n`;

fs.writeFileSync("public/config.js", content);
console.log("public/config.js généré.");
