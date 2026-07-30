from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('syncplay', '0003_room_room_mode'),
    ]

    operations = [
        migrations.AlterField(
            model_name='room',
            name='room_mode',
            field=models.CharField(
                choices=[
                    ('friends', 'Friends'),
                    ('couple', 'Couple'),
                    ('party', 'Party'),
                    ('horror', 'Horror'),
                    ('roast', 'Roast'),
                    ('movieClub', 'Movie Club'),
                ],
                default='friends',
                max_length=16,
            ),
        ),
    ]
