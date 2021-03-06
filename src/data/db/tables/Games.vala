using Gee;
using Sqlite;

using GameHub.Utils;

using GameHub.Data.Sources.Steam;
using GameHub.Data.Sources.GOG;
using GameHub.Data.Sources.Humble;

namespace GameHub.Data.DB.Tables
{
	public class Games: Table
	{
		public static Games instance;

		public static Table.Field SOURCE;
		public static Table.Field ID;
		public static Table.Field NAME;
		public static Table.Field INFO;
		public static Table.Field INFO_DETAILED;
		public static Table.Field ICON;
		public static Table.Field IMAGE;
		public static Table.Field TAGS;
		public static Table.Field INSTALL_PATH;
		public static Table.Field EXECUTABLE;
		public static Table.Field PLATFORMS;
		public static Table.Field COMPAT_TOOL;
		public static Table.Field COMPAT_TOOL_SETTINGS;

		public Games()
		{
			instance             = this;

			SOURCE               = f(0);
			ID                   = f(1);
			NAME                 = f(2);
			INFO                 = f(3);
			INFO_DETAILED        = f(4);
			ICON                 = f(5);
			IMAGE                = f(6);
			TAGS                 = f(7);
			INSTALL_PATH         = f(8);
			EXECUTABLE           = f(9);
			PLATFORMS            = f(10);
			COMPAT_TOOL          = f(11);
			COMPAT_TOOL_SETTINGS = f(12);
		}

		public override void migrate(Sqlite.Database db, int version)
		{
			switch(version)
			{
				case 0:
					debug("%d", version);
					db.exec("CREATE TABLE `games`(
						`source`               string not null,
						`id`                   string not null,
						`name`                 string not null,
						`info`                 string,
						`info_detailed`        string,
						`icon`                 string,
						`image`                string,
						`tags`                 string,
						`install_path`         string,
						`executable`           string,
						`platforms`            string,
						`compat_tool`          string,
						`compat_tool_settings` string,
					PRIMARY KEY(`source`, `id`))");
					migrate(db, 1);
					break;
			}
		}

		public static bool add(Game game)
		{
			if(game is Sources.GOG.GOGGame.DLC) return false;
			//if(game is Sources.Humble.HumbleGame && ((Sources.Humble.HumbleGame) game).order_id == Sources.Humble.Trove.FAKE_ORDER) return false;

			unowned Sqlite.Database? db = Database.instance.db;
			if(db == null) return false;

			Statement s;
			int res = db.prepare_v2("INSERT OR REPLACE INTO `games`(
					`source`,
					`id`,
					`name`,
					`info`,
					`info_detailed`,
					`icon`,
					`image`,
					`tags`,
					`install_path`,
					`executable`,
					`platforms`,
					`compat_tool`,
					`compat_tool_settings`)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", -1, out s);

			if(res != Sqlite.OK)
			{
				warning("[Database.Games.add] Can't prepare INSERT query (%d): %s", db.errcode(), db.errmsg());
				return false;
			}

			var platforms = "";
			foreach(var p in game.platforms)
			{
				if(platforms.length > 0) platforms += ",";
				platforms += p.id();
			}

			var tags = "";
			foreach(var t in game.tags)
			{
				if(t == Tables.Tags.BUILTIN_INSTALLED) continue;
				if(tags.length > 0) tags += ",";
				tags += t.id;
			}

			SOURCE.bind(s, game.source.id);
			ID.bind(s, game.id);
			NAME.bind(s, game.name);
			INFO.bind(s, game.info);
			INFO_DETAILED.bind(s, game.info_detailed);
			ICON.bind(s, game.icon);
			IMAGE.bind(s, game.image);
			TAGS.bind(s, tags);
			EXECUTABLE.bind(s, game.executable == null || !game.executable.query_exists() ? null : game.executable.get_path());
			INSTALL_PATH.bind(s, game.install_dir == null || !game.install_dir.query_exists() ? null : game.install_dir.get_path());
			PLATFORMS.bind(s, platforms);
			COMPAT_TOOL.bind(s, game.compat_tool);
			COMPAT_TOOL_SETTINGS.bind(s, game.compat_tool_settings);

			res = s.step();

			if(res != Sqlite.DONE)
			{
				warning("[Database.Games.add] Error (%d): %s", db.errcode(), db.errmsg());
				return false;
			}

			return true;
		}

		public static new Game? get(string src, string id)
		{
			if(src == null || id == null) return null;

			unowned Sqlite.Database? db = Database.instance.db;
			if(db == null) return null;

			Statement st;
			int res;

			res = db.prepare_v2("SELECT * FROM `games` WHERE `source` = ? AND `id` = ?", -1, out st);
			res = st.bind_text(1, src);
			res = st.bind_text(2, id);

			if(res != Sqlite.OK)
			{
				warning("[Database.Games.get] Can't prepare SELECT query (%d): %s", db.errcode(), db.errmsg());
				return null;
			}

			if((res = st.step()) == Sqlite.ROW)
			{
				var s = GameSource.by_id(SOURCE.get(st));

				if(s is Steam)
				{
					return new SteamGame.from_db((Steam) s, st);
				}
				else if(s is GOG)
				{
					return new GOGGame.from_db((GOG) s, st);
				}
				else if(s is Humble)
				{
					return new HumbleGame.from_db((Humble) s, st);
				}
			}

			return null;
		}

		public static ArrayList<Game>? get_all(GameSource? src = null)
		{
			unowned Sqlite.Database? db = Database.instance.db;
			if(db == null) return null;

			Statement st;
			int res;

			if(src != null)
			{
				res = db.prepare_v2("SELECT * FROM `games` WHERE `source` = ? ORDER BY `name` ASC", -1, out st);
				res = st.bind_text(1, src.id);
			}
			else
			{
				res = db.prepare_v2("SELECT * FROM `games` ORDER BY `name` ASC", -1, out st);
			}

			if(res != Sqlite.OK)
			{
				warning("[Database.Games.get_all] Can't prepare SELECT query (%d): %s", db.errcode(), db.errmsg());
				return null;
			}

			var games = new ArrayList<Game>(Game.is_equal);

			while((res = st.step()) == Sqlite.ROW)
			{
				var s = GameSource.by_id(SOURCE.get(st));

				if(s is Steam)
				{
					games.add(new SteamGame.from_db((Steam) s, st));
				}
				else if(s is GOG)
				{
					games.add(new GOGGame.from_db((GOG) s, st));
				}
				else if(s is Humble)
				{
					games.add(new HumbleGame.from_db((Humble) s, st));
				}
			}

			return games;
		}
	}
}
