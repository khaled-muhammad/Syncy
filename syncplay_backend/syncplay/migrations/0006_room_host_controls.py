from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('syncplay', '0005_room_join_code'),
    ]

    operations = [
        migrations.AddField(
            model_name='room',
            name='is_locked',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='room',
            name='seek_permission',
            field=models.CharField(
                choices=[
                    ('host', 'Host only'),
                    ('everyone', 'Everyone'),
                    ('selected', 'Selected participants'),
                ],
                default='everyone',
                max_length=10,
            ),
        ),
        migrations.AddField(
            model_name='user',
            name='can_seek',
            field=models.BooleanField(default=False),
        ),
        migrations.AlterField(
            model_name='message',
            name='message_type',
            field=models.CharField(
                choices=[
                    ('join', 'Join'),
                    ('leave', 'Leave'),
                    ('play', 'Play'),
                    ('pause', 'Pause'),
                    ('seek', 'Seek'),
                    ('video_changed', 'Video Changed'),
                    ('room_update', 'Room Update'),
                    ('user_joined', 'User Joined'),
                    ('user_left', 'User Left'),
                    ('error', 'Error'),
                    ('heartbeat', 'Heartbeat'),
                    ('room_settings', 'Room Settings'),
                    ('participant_removed', 'Participant Removed'),
                ],
                max_length=20,
            ),
        ),
    ]
