from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('syncplay', '0001_initial')]

    operations = [
        migrations.AddField(
            model_name='room',
            name='playback_revision',
            field=models.PositiveBigIntegerField(default=0),
        ),
    ]
