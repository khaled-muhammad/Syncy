import secrets

from django.db import migrations, models


ALPHABET = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'
CODE_LENGTH = 8


def add_join_codes(apps, schema_editor):
    room_model = apps.get_model('syncplay', 'Room')
    allocated = set(
        room_model.objects.exclude(join_code__isnull=True).values_list(
            'join_code', flat=True
        )
    )
    for room in room_model.objects.filter(join_code__isnull=True).iterator():
        while True:
            code = ''.join(secrets.choice(ALPHABET) for _ in range(CODE_LENGTH))
            if code not in allocated:
                break
        allocated.add(code)
        room.join_code = code
        room.save(update_fields=['join_code'])


class Migration(migrations.Migration):

    dependencies = [
        ('syncplay', '0004_room_preset_choices'),
    ]

    operations = [
        migrations.AddField(
            model_name='room',
            name='join_code',
            field=models.CharField(
                blank=True,
                db_index=True,
                editable=False,
                max_length=8,
                null=True,
                unique=True,
            ),
        ),
        migrations.RunPython(add_join_codes, migrations.RunPython.noop),
        migrations.AlterField(
            model_name='room',
            name='join_code',
            field=models.CharField(
                db_index=True,
                editable=False,
                max_length=8,
                unique=True,
            ),
        ),
    ]
