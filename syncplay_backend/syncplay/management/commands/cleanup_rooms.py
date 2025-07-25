from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from syncplay.models import Room, User, RoomSession

class Command(BaseCommand):
    help = 'Clean up old empty rooms and inactive users'

    def add_arguments(self, parser):
        parser.add_argument(
            '--hours',
            type=int,
            default=24,
            help='Remove rooms older than this many hours (default: 24)',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be deleted without actually deleting',
        )

    def handle(self, *args, **options):
        hours = options['hours']
        dry_run = options['dry_run']
        cutoff_time = timezone.now() - timedelta(hours=hours)
        
        self.stdout.write(f"Cleaning up rooms older than {hours} hours...")
        
        # Find empty rooms older than cutoff time
        empty_rooms = Room.objects.filter(
            created_at__lt=cutoff_time,
            users__isnull=True
        )
        
        # Find rooms with only inactive users
        inactive_rooms = Room.objects.filter(
            created_at__lt=cutoff_time,
            users__last_seen__lt=cutoff_time
        ).distinct()
        
        # Clean up old sessions
        old_sessions = RoomSession.objects.filter(
            last_activity__lt=cutoff_time
        )
        
        if dry_run:
            self.stdout.write("DRY RUN - No actual deletions will be performed")
            self.stdout.write(f"Would delete {empty_rooms.count()} empty rooms")
            self.stdout.write(f"Would delete {inactive_rooms.count()} inactive rooms")
            self.stdout.write(f"Would delete {old_sessions.count()} old sessions")
        else:
            # Delete old sessions first
            sessions_deleted = old_sessions.count()
            old_sessions.delete()
            
            # Delete inactive rooms (this will cascade delete users)
            inactive_deleted = inactive_rooms.count()
            inactive_rooms.delete()
            
            # Delete empty rooms
            empty_deleted = empty_rooms.count()
            empty_rooms.delete()
            
            self.stdout.write(
                self.style.SUCCESS(
                    f'Successfully cleaned up:'
                    f'\n- {empty_deleted} empty rooms'
                    f'\n- {inactive_deleted} inactive rooms'
                    f'\n- {sessions_deleted} old sessions'
                )
            )
        
        # Show current stats
        current_rooms = Room.objects.count()
        current_users = User.objects.count()
        current_sessions = RoomSession.objects.count()
        
        self.stdout.write(f"\nCurrent stats:")
        self.stdout.write(f"- Active rooms: {current_rooms}")
        self.stdout.write(f"- Active users: {current_users}")
        self.stdout.write(f"- Active sessions: {current_sessions}") 