# home/models.py
#User,Fingerprint,RFID
from django.db import models

class User(models.Model):
    name = models.CharField(max_length=255)
    email = models.EmailField(unique=True)
    balance = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    fingerprint_id = models.CharField(max_length=255, null=True, blank=True)
    rfid_tag = models.CharField(max_length=255, null=True, blank=True)

    def __str__(self):
        return self.name

class Fingerprint(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    fingerprint_data = models.TextField()  # You can store fingerprint data here, or save as a path to file.

    def __str__(self):
        return f"Fingerprint of {self.user.name}"

class RFID(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    rfid_tag = models.CharField(max_length=255, unique=True)

    def __str__(self):
        return f"RFID Tag for {self.user.name}"
