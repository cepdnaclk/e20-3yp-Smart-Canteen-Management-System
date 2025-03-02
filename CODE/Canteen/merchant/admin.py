from django.contrib import admin
from .models import Merchant,Menu,Order,Transaction
# Register your models here.

admin.site.register(Merchant)
admin.site.register(Menu)
admin.site.register(Order)
admin.site.register(Transaction)