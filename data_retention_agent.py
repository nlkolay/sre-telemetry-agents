# Автоматическая очистка СХД на базе API Jellyfin и Radarr с Fail-Safe логикой)
import requests, json, logging, sys
from datetime import datetime

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')

JF_URL = "http://127.0.0.1:8096"
JF_KEY = "API_KEY"
RADARR_URL = "http://127.0.0.1:7878"
RADARR_KEY = "API_KEY"
RETENTION_DAYS = 30

def check_and_clean():
    users = requests.get(f"{JF_URL}/Users", headers={'X-Emby-Token': JF_KEY}).json()
    movies = requests.get(f"{RADARR_URL}/api/v3/movie", headers={'X-Api-Key': RADARR_KEY}).json()

    for movie in movies:
        if not movie.get('hasFile'): continue
        tmdb_id = movie.get('tmdbId')
        
        # Поиск по TMDB ID
        jf_search = requests.get(f"{JF_URL}/Items?AnyProviderIdEquals=tmdb.{tmdb_id}&IncludeItemTypes=Movie", headers={'X-Emby-Token': JF_KEY}).json()
        if not jf_search.get('Items'): continue
        
        jf_id = jf_search['Items'][0]['Id']
        safe_to_delete = True
        
        for user in users:
            u_data = requests.get(f"{JF_URL}/Users/{user['Id']}/Items/{jf_id}", headers={'X-Emby-Token': JF_KEY}).json().get('UserData', {})
            
            # Fail-Safe: Не удалять избранное
            if u_data.get('IsFavorite', False):
                safe_to_delete = False; break
                
            # Fail-Safe: Не удалять непросмотренное
            if not u_data.get('Played', False):
                safe_to_delete = False; break
                
        if safe_to_delete:
            logging.info(f"[DELETE COMMAND] Movie: {movie['title']}")
            # requests.delete(f"{RADARR_URL}/api/v3/movie/{movie['id']}?deleteFiles=true", headers={'X-Api-Key': RADARR_KEY})

if __name__ == "__main__":
    check_and_clean()
