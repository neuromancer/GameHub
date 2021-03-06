using Gee;
using Sqlite;

using GameHub.Utils;

using GameHub.Data.Sources.Steam;
using GameHub.Data.Sources.GOG;
using GameHub.Data.Sources.Humble;

namespace GameHub.Data.DB
{
	public class Database
	{
		public const int VERSION = 1;
		public static Table[] TABLES;

		public static Database instance;

		public Sqlite.Database? db = null;

		public Database()
		{
			instance = this;

			var path = FSUtils.expand(FSUtils.Paths.Cache.Database);

			var db_file = File.new_for_path(path);
			var db_backup = db_file.get_parent().get_child(db_file.get_basename() + ".old");

			bool err = false;
			while(Sqlite.Database.open_v2(path, out db, Sqlite.OPEN_READWRITE | Sqlite.OPEN_CREATE) != Sqlite.OK)
			{
				warning("[Database] Can't open database (%d): %s", db.errcode(), db.errmsg());

				if(err)
				{
					error("[Database] Can't recreate database. Remove '%s' manually and make sure GameHub can write into cache directory", path);
				}

				err = true;

				try
				{
					db_file.move(db_backup, FileCopyFlags.BACKUP | FileCopyFlags.OVERWRITE);
				}
				catch(Error e)
				{
					error("[Database] Can't backup current database: %s", e.message);
				}
			}

			TABLES = { new Tables.Games(), new Tables.Tags(), new Tables.Merges() };

			migrate();
			init();
		}

		private void migrate()
		{
			Statement s;

			int version = 0;
			int res = db.prepare_v2("PRAGMA user_version", -1, out s);

			if((res = s.step()) == Sqlite.ROW)
			{
				version = s.column_int(0);

				debug("[Database.migrate] Latest db version: %d, current: %d", VERSION, version);

				if(version < VERSION)
				{
					debug("[Database.migrate] Migrating database from version %d to %d", version, VERSION);

					foreach(var table in TABLES)
					{
						table.migrate(db, version);
					}

					debug("[Database.migrate] Migration completed, new version: %d", VERSION);

					res = db.exec(@"PRAGMA user_version = $(VERSION)");

					if(res != Sqlite.OK)
					{
						warning("[Database.migrate] Can't update version (%d): %s", db.errcode(), db.errmsg());
					}
				}
			}
		}

		private void init()
		{
			foreach(var table in TABLES)
			{
				table.init(db);
			}
		}

		public static void create()
		{
			instance = new Database();
		}
	}
}
