from .views import chatBot , home
from django.urls import path

urlpatterns = [
    path('',home),
    path("ask-ai/", chatBot),
]


