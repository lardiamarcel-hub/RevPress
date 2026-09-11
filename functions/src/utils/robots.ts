/**
 * Vérification minimaliste de robots.txt avant tout fetch direct d'un flux.
 * On ne fait volontairement pas de scraping HTML de sites tiers (voir
 * ARCHITECTURE.md) : cette fonction protège uniquement les requêtes de
 * flux (RSS / Google News RSS) contre un `Disallow: /` global.
 */
export async function isFetchAllowed(feedUrl: string): Promise<boolean> {
  try {
    const url = new URL(feedUrl);
    const robotsUrl = `${url.protocol}//${url.host}/robots.txt`;
    const response = await fetch(robotsUrl, { signal: AbortSignal.timeout(5000) });
    if (!response.ok) {
      // Pas de robots.txt accessible : on suppose que la collecte est autorisée.
      return true;
    }
    const body = await response.text();
    return !disallowsPath(body, url.pathname);
  } catch {
    // En cas d'erreur réseau sur robots.txt, on ne bloque pas la collecte du flux.
    return true;
  }
}

function disallowsPath(robotsTxt: string, path: string): boolean {
  const lines = robotsTxt.split('\n').map((l) => l.trim());
  let applies = false;
  for (const line of lines) {
    const [rawKey, ...rest] = line.split(':');
    const key = rawKey?.trim().toLowerCase();
    const value = rest.join(':').trim();
    if (key === 'user-agent') {
      applies = value === '*';
    } else if (applies && key === 'disallow' && value) {
      if (value === '/' || path.startsWith(value)) {
        return true;
      }
    }
  }
  return false;
}
