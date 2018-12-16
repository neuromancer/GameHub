/*
This file is part of GameHub.
Copyright (C) 2018 Anatoliy Kashkin

GameHub is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

GameHub is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GameHub.  If not, see <https://www.gnu.org/licenses/>.
*/

using GameHub.Utils;
using GameHub.Data.Sources.Steam;

namespace GameHub.Data.Compat
{
	public class Proton: Wine
	{
		protected override string install_postfix() { return @"/$(FSUtils.GAMEHUB_DIR)/proton_$(appid)/pfx/drive_c/Game"; }
		public const string[] APPIDS = {"961940", "930400", "858280"}; // 3.16, 3.7 Beta, 3.7

		public string appid { get; construct; }

		public Proton(string appid)
		{
			Object(appid: appid, binary: "", arch: "");
		}

		construct
		{
			id = @"proton_$(appid)";
			name = "Proton";
			icon = "source-steam-symbolic";
			installed = false;

			opt_env = new CompatTool.StringOption("env", _("Environment variables"), null);

			options = {
				opt_env,
				new CompatTool.BoolOption("PROTON_NO_ESYNC", _("Disable esync"), false),
				new CompatTool.BoolOption("PROTON_NO_D3D11", _("Disable DirectX 11 compatibility layer"), false),
				new CompatTool.BoolOption("PROTON_USE_WINED3D11", _("Use WineD3D11 as DirectX 11 compatibility layer"), false),
				new CompatTool.BoolOption("DXVK_HUD", _("Show DXVK info overlay"), true)
			};

			File? proton_dir = null;
			if(Steam.find_app_install_dir(appid, out proton_dir))
			{
				if(proton_dir != null)
				{
					name = proton_dir.get_basename();
					executable = proton_dir.get_child("proton");
					installed = executable.query_exists();
					wine_binary = proton_dir.get_child("dist/bin/wine");
				}
			}

			if(installed)
			{
				actions = {
					new CompatTool.Action("prefix", _("Open prefix directory"), r => {
						Utils.open_uri(get_wineprefix(r).get_uri());
					}),
					new CompatTool.Action("winecfg", _("Run winecfg"), r => {
						wineutil.begin(null, r, "winecfg");
					}),
					new CompatTool.Action("winetricks", _("Run winetricks"), r => {
						winetricks.begin(null, r);
					}),
					new CompatTool.Action("taskmgr", _("Run taskmgr"), r => {
						wineutil.begin(null, r, "taskmgr");
					}),
					new CompatTool.Action("kill", _("Kill apps in prefix"), r => {
						wineboot.begin(null, r, {"-k"});
					})
				};
			}
		}

		protected override async void exec(Runnable runnable, File file, File dir, string s="", string[]? args=null, bool parse_opts=true)
		{
			string[] cmd = { executable.get_path(), "run", file.get_path() };
			if(file.get_path().down().has_suffix(".msi"))
			{
				cmd = { executable.get_path(), "run", "msiexec", "/i", file.get_path() };
			}
			if(args != null)
			{
				foreach(var arg in args) cmd += arg;
			}
			yield Utils.run_thread(cmd, dir.get_path() + s, prepare_env(runnable, parse_opts));
		}

		protected override File get_wineprefix(Runnable runnable)
		{
			var prefix = FSUtils.mkdir(runnable.install_dir.get_path(), @"$(FSUtils.GAMEHUB_DIR)/proton_$(appid)/pfx");
                        var dosdevices = prefix.get_child("dosdevices");

			/*if(FSUtils.file(runnable.install_dir.get_path(), @"$(FSUtils.GAMEHUB_DIR)/$(id)").query_exists())
			{
				Utils.run({"bash", "-c", @"mv -f $(FSUtils.GAMEHUB_DIR)/$(id) $(FSUtils.GAMEHUB_DIR)/$(FSUtils.COMPAT_DATA_DIR)/$(id)"}, runnable.install_dir.get_path());
				FSUtils.rm(dosdevices.get_child("d:").get_path());
			}*/

			if(dosdevices.get_child("c:").query_exists() && !dosdevices.get_child("d:").query_exists())
			{
				Utils.run({"ln", "-nsf", "../../../../../", "d:"}, dosdevices.get_path());
			}
			return prefix;
		}

		protected override string[] prepare_env(Runnable runnable, bool parse_opts=true)
		{
			var env = Environ.get();

			var compatdata = FSUtils.mkdir(runnable.install_dir.get_path(), @"$(FSUtils.GAMEHUB_DIR)/proton_$(appid)");
			if(compatdata != null && compatdata.query_exists())
			{
				env = Environ.set_variable(env, "STEAM_COMPAT_CLIENT_INSTALL_PATH", FSUtils.Paths.Steam.Home);
				env = Environ.set_variable(env, "STEAM_COMPAT_DATA_PATH", compatdata.get_path());
				env = Environ.set_variable(env, "PROTON_LOG", "1");
				env = Environ.set_variable(env, "PROTON_DUMP_DEBUG_COMMANDS", "1");
			}

			if(parse_opts)
			{
				if(opt_env.value != null && opt_env.value.length > 0)
				{
					var evars = opt_env.value.split(" ");
					foreach(var ev in evars)
					{
						var v = ev.split("=");
						env = Environ.set_variable(env, v[0], v[1]);
					}
				}

				foreach(var opt in options)
				{
					if(opt is CompatTool.BoolOption && ((CompatTool.BoolOption) opt).enabled)
					{
						env = Environ.set_variable(env, opt.name, "1");
					}
				}
			}

			return env;
		}

		protected override async void wineboot(File? wineprefix, Runnable runnable, string[]? args=null)
		{
			if(args == null)
			{
				yield proton_init_prefix(wineprefix, runnable);
			}

			yield wineutil(wineprefix, runnable, "wineboot", args);
		}

		protected async void proton_init_prefix(File? wineprefix, Runnable runnable)
		{
			var env = prepare_env(runnable, false);
			env = Environ.set_variable(env, "WINE", wine_binary.get_path());
			env = Environ.set_variable(env, "WINEDLLOVERRIDES", "mshtml=d");
			var prefix = wineprefix ?? get_wineprefix(runnable);
			if(prefix != null && prefix.query_exists())
			{
				env = Environ.set_variable(env, "WINEPREFIX", prefix.get_path());
			}
			if(arch != null && arch.length > 0)
			{
				env = Environ.set_variable(env, "WINEARCH", arch);
			}

			yield Utils.run_thread({ executable.get_path(), "run" }, runnable.install_dir.get_path(), env);
		}
	}
	

}
