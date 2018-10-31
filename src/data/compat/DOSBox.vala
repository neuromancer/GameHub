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

using Gee;

using GameHub.Utils;

namespace GameHub.Data.Compat
{
	public class DOSBox: CompatTool
	{
		public string binary { get; construct; default = "dosbox"; }

		private File conf_windowed;
                private ArrayList<ArrayList<string>> multi_config; 
		private CompatTool.BoolOption? opt_windowed;

		public DOSBox(string binary="dosbox")
		{
			Object(binary: binary);
		}

		construct
		{
			id = @"dosbox";
			name = @"DOSBox";
			icon = "tool-dosbox-symbolic";
                        multi_config = new ArrayList<ArrayList<string>>();

			executable = Utils.find_executable(binary);
			installed = executable != null && executable.query_exists();

			conf_windowed = FSUtils.file(ProjectConfig.DATADIR + "/" + ProjectConfig.PROJECT_NAME, "compat/dosbox/windowed.conf");
			if(conf_windowed.query_exists())
			{
				opt_windowed = new CompatTool.BoolOption(_("Windowed"), _("Disable fullscreen"), true);
				options = { opt_windowed };
			}
		}

		private static ArrayList<string> find_configs(File? dir)
		{
			var configs = new ArrayList<string>();

			if(dir == null || !dir.query_exists())
			{
				return configs;
			}

			try
			{
				FileInfo? finfo = null;
				var enumerator = dir.enumerate_children("standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
				while((finfo = enumerator.next_file()) != null)
				{
					var fname = finfo.get_name();
					if(fname.has_suffix(".conf"))
					{
						configs.add(dir.get_child(fname).get_path());
					}
				}
			}
			catch(Error e)
			{
				warning("[DOSBox.find_configs] %s", e.message);
			}
                        if (configs.size == 1)
                        {
				return configs;
                        }

                        foreach (string s in configs)
                        {
				if (s.contains("_single.conf")) {
					configs.clear();
					configs.add(s);
					configs.add(s.replace("_single",""));
					return configs;
                                }
                        }

			return configs;
		}

		public override bool can_run(Runnable game)
		{
                        var configs = find_configs(game.install_dir);
                        multi_config.clear();
                        var has_configs = configs.size > 0;
                        if (has_configs) {
                            warning("Found dir %s with dosbox conf", game.install_dir.get_path());       
                            multi_config.add(configs);
                        }
                       	FileInfo? finfo = null;
			var enumerator = game.install_dir.enumerate_children("standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
			while((finfo = enumerator.next_file()) != null)
			{
                          if (finfo.get_file_type () == FileType.DIRECTORY) {
                              File subdir = game.install_dir.resolve_relative_path (finfo.get_name ());
                              configs = find_configs(subdir);
                              has_configs = has_configs || configs.size > 0; 

                              if (configs.size > 0) {
                                  warning("Found dir %s with dosbox conf", subdir.get_path()); 
                                  multi_config.add(configs);
                              }
 
                          }
                        }
	
			return installed && game is Game  && has_configs; //&& find_configs(game.install_dir).size > 0;
		}

		public override async void run(Runnable game)
		{
			if(!can_run(game)) return;
                        warning("multi_config size %d", multi_config.size);

			string[] cmd = { executable.get_path() };

			var wdir = game.install_dir;

			var configs = multi_config.get(0); // select some configs
                        
			if(configs.size > 2 && game is GameHub.Data.Sources.GOG.GOGGame)
			{
				foreach(var conf in configs)
				{
                                        warning("Found .conf file: %s", conf); 
					if(conf.has_suffix("_single.conf"))
					{
						configs.clear();
						configs.add(conf.replace("_single.conf", ".conf"));
						configs.add(conf);
						break;
					}
				}
			}

			foreach(var conf in configs)
			{
				cmd += "-conf";
				cmd += conf;
			}

			if(conf_windowed.query_exists() && opt_windowed != null && opt_windowed.enabled)
			{
				cmd += "-conf";
				cmd += conf_windowed.get_path();
			}

			if(game.install_dir.get_child("DOSBOX").get_child("DOSBox.exe").query_exists() || 
                           game.install_dir.get_child("DOSBOX").get_child("dosbox.exe").query_exists())
			{
				wdir = game.install_dir.get_child("DOSBOX");
			}

			yield Utils.run_thread(cmd, wdir.get_path());
		}
	}
}
