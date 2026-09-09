// Fonction serveur Vercel : relaie une image de logo d'équipe depuis
// crests.football-data.org avec un en-tête CORS ouvert, pour pouvoir la
// dessiner dans un <canvas> (génération d'affiches) sans "tainted canvas".
// Restreint volontairement au domaine des crests pour ne pas devenir un
// proxy ouvert vers n'importe quelle URL.
module.exports = async (req, res) => {
  const { url } = req.query;
  if (!url || !/^https:\/\/crests\.football-data\.org\//.test(url)) {
    res.status(400).json({ error: "URL de logo invalide." });
    return;
  }

  try {
    const imgRes = await fetch(url);
    if (!imgRes.ok) {
      res.status(imgRes.status).end();
      return;
    }
    const buffer = Buffer.from(await imgRes.arrayBuffer());
    res.setHeader("Content-Type", imgRes.headers.get("content-type") || "image/png");
    res.setHeader("Cache-Control", "public, max-age=86400");
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.status(200).send(buffer);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};
