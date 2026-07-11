from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('syncplay', '0002_room_playback_revision')]

    operations = [
        migrations.AddField(
            model_name='room',
            name='room_mode',
            field=models.CharField(
                choices=[('friends', 'Friends'), ('couple', 'Couple')],
                default='friends',
                max_length=12,
            ),
        ),
    ]
