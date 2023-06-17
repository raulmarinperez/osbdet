from django.shortcuts import render
from django.contrib.auth.models import User, Group
from .models import Command
from rest_framework import viewsets
from rest_framework import permissions
from .serializers import CommandSerializer # UserSerializer, GroupSerializer,
from django.http import HttpResponse, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from rest_framework.parsers import JSONParser
import subprocess 
import json

class CommandViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows groups to be viewed or edited.
    """
    queryset = Command.objects.all()
    serializer_class = CommandSerializer
#    permission_classes = [permissions.IsAuthenticated]

@csrf_exempt
def command(request):
    """
    List all the commands, or create a new command.
    """
    if request.method == 'POST':
        print(request.POST)
        data = JSONParser().parse(request)
        serializer = CommandSerializer(data = data)
        if serializer.is_valid():
            try:
                res = subprocess.run(
                    ["sudo", "service", data["service"], data["operation"]], 
                    capture_output = True, text = True)
                response = {
                    "code": res.returncode,
                    "output": res.stdout,
                    "errors": res.stderr
                }
            except Exception as e:
                print(e)
            serializer.save()
            return JsonResponse(response, status = 201)
        return JsonResponse(response, status = 400)  

#    elif request.method == 'GET':
#        commands = Command.objects.all()
#        serializer = CommandSerializer(commands, many = True)
#        return JsonResponse(serializer.data, safe = False)


