// Vérifie le code PIN d'accès à admin.html côté serveur : le vrai code
// (ADMIN_PIN, variable d'environnement Vercel) n'est jamais envoyé au
// navigateur, contrairement à un code stocké dans config.js qui serait
// visible par n'importe qui visitant n'importe quelle page du site.
module.exports = async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: "Méthode non autorisée." });
    return;
  }

  // Valeur par défaut pour que ça marche sans configuration Vercel. Pour la
  // changer plus tard sans toucher au code, ajoute une variable
  // d'environnement ADMIN_PIN sur Vercel : elle prend le dessus sur celle-ci.
  const adminPin = process.env.ADMIN_PIN || "7411";

  const { pin } = req.body || {};
  const ok = typeof pin === "string" && pin.length > 0 && pin === adminPin;
  res.status(ok ? 200 : 401).json({ ok });
};
