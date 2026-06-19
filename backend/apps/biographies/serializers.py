from rest_framework import serializers
from .models import Biographie


class BiographieSerializer(serializers.ModelSerializer):
    class Meta:
        model = Biographie
        fields = '__all__'
