class NoCacheAPIMiddleware:
    """Empêche les navigateurs (notamment Safari iOS) de mettre en cache les
    réponses de l'API, qui servent des données dynamiques (listes d'audios,
    vidéos, citations…). Sans cela, un client peut continuer d'afficher une
    liste périmée même après publication d'un nouveau contenu."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        if request.path.startswith('/api/'):
            response['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
            response['Pragma'] = 'no-cache'
        return response
