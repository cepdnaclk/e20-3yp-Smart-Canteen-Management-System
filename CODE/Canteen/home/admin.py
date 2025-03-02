from django.contrib import admin
from .models import User,Fingerprint,RFID
# Register your models here.
admin.site.register(User)
admin.site.register(Fingerprint)
admin.site.register(RFID)