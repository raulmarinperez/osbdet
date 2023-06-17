from django.db import models
from django.utils.translation import gettext_lazy as _

class Command(models.Model):

    class Service(models.TextChoices):
        JUPYTER = "jupyter", _("jupyter")
        NIFI = "nifi", _("nifi")
        HADOOP = "hadoop", _("hadoop")
        SPARK = "spark", _("spark")
        KAFKA = "kafka", _("kafka")        
        MARIADB = "mariadb", _("mariadb")
        #MYSQL = "mysql", _("mysql")
        SUPERSET = "superset", _("superset")
        MONGODB = "mongodb", _("mongodb")
        MINIO = "minio", _("minio")
        AIRFLOW = "airflow", _("airflow")  
        TRUCKFLEET_SIM = "truckfleet-sim", _("truckfleet-sim")          

    class Operation(models.TextChoices):
        START = "start", _("start")
        STOP = "stop", _("stop")
        STATUS = "status", _("status")

    service = models.CharField(
        max_length = 20,
        choices = Service.choices,
        default = Service.JUPYTER
    )
    operation = models.CharField(
        max_length = 10,
        choices = Operation.choices,
        default = Operation.STATUS
    )
    creation_date = models.DateTimeField(
        auto_now = True
    )

    class Meta:
        ordering = ['creation_date']