// Fonction serveur Vercel : sert de relais vers football-data.org pour
// contourner le blocage CORS de leur API sur les appels directs depuis un
// navigateur, et garder la clé API côté serveur (jamais envoyée au client).
module.exports = async (req, res) => {
  const { date } = req.query;
  if (!date) {
    res.status(400).json({ error: "Paramètre 'date' manquant (format YYYY-MM-DD)." });
    return;
  }

  const apiKey = process.env.FOOTBALL_DATA_API_KEY;
  const competitionCode = process.env.COMPETITION_CODE || "CL";

  if (!apiKey) {
    res.status(500).json({ error: "FOOTBALL_DATA_API_KEY non configurée sur Vercel." });
    return;
  }

  try {
    const url = `https://api.football-data.org/v4/competitions/${competitionCode}/matches?dateFrom=${date}&dateTo=${date}`;
    const apiRes = await fetch(url, { headers: { "X-Auth-Token": apiKey } });
    const data = await apiRes.json();

    if (!apiRes.ok) {
      res.status(apiRes.status).json({ error: data.message || "Erreur API football-data.org" });
      return;
    }

    res.status(200).json(data);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};
