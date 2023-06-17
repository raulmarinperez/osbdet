from django.http import HttpResponse
from django.shortcuts import get_object_or_404, render

def index(request):
    #question = get_object_or_404(Question, pk=question_id)
    context = None
    return render(request, 
        "frontend/index.html", context)      

def detail(request, service):
    context = None
    return render(request, 
        f"frontend/{service}", context)  
