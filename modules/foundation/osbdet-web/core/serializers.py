from django.contrib.auth.models import User, Group
from .models import Command
from rest_framework import serializers

class CommandSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Command
        fields = ['service', 'operation']