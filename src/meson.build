conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('GETTEXT_DIR', get_option('prefix') + '/' + get_option('localedir'))
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', get_option('prefix'))
conf_data.set_quoted('DATADIR', get_option('prefix') + '/' + get_option('datadir'))
conf_data.set_quoted('RUNTIME', get_option('runtime'))
project_config = configure_file(
	input: 'ProjectConfig.vala.in',
	output: 'ProjectConfig.vala',
	configuration: conf_data
)

deps = [
	dependency('granite'),
	dependency('gdk-3.0'),
	dependency('webkit2gtk-4.0'),
	dependency('glib-2.0'),
	dependency('json-glib-1.0'),
	dependency('gee-0.8'),
	dependency('sqlite3'),
	dependency('libsoup-2.4'),
	dependency('libxml-2.0'),
	meson.get_compiler('vala').find_library('posix'),
	meson.get_compiler('vala').find_library('linux')
]

gtk322 = dependency('gtk+-3.0', version: '>=3.22', required: false)
if gtk322.found()
	add_global_arguments('-D', 'GTK_3_22', language: 'vala')
	deps += gtk322
else
	deps += dependency('gtk+-3.0')
endif

executable(
	meson.project_name(),
	project_config,

	'app.vala',

	'data/Game.vala',
	'data/GameSource.vala',

	'data/sources/steam/Steam.vala',
	'data/sources/steam/SteamGame.vala',

	'data/sources/gog/GOG.vala',
	'data/sources/gog/GOGGame.vala',

	'data/sources/humble/Humble.vala',
	'data/sources/humble/HumbleGame.vala',
	'data/sources/humble/Trove.vala',

	'data/db/Database.vala',
	'data/db/Table.vala',
	'data/db/tables/Games.vala',
	'data/db/tables/Tags.vala',
	'data/db/tables/Merges.vala',

	'data/CompatTool.vala',
	'data/compat/CustomScript.vala',
	'data/compat/Innoextract.vala',
	'data/compat/Proton.vala',
	'data/compat/Wine.vala',
	'data/compat/DOSBox.vala',

	'ui/windows/MainWindow.vala',
	'ui/windows/WebAuthWindow.vala',

	'ui/dialogs/SettingsDialog/SettingsDialog.vala',
	'ui/dialogs/SettingsDialog/SettingsDialogTab.vala',

	'ui/dialogs/SettingsDialog/tabs/UI.vala',
	'ui/dialogs/SettingsDialog/tabs/Steam.vala',
	'ui/dialogs/SettingsDialog/tabs/GOG.vala',
	'ui/dialogs/SettingsDialog/tabs/Humble.vala',
	'ui/dialogs/SettingsDialog/tabs/Collection.vala',

	'ui/dialogs/GameInstallDialog.vala',
	'ui/dialogs/GameDetailsDialog.vala',
	'ui/dialogs/GamePropertiesDialog.vala',
	'ui/dialogs/CompatRunDialog.vala',

	'ui/views/BaseView.vala',
	'ui/views/WelcomeView.vala',

	'ui/views/GamesView/GamesView.vala',
	'ui/views/GamesView/GameCard.vala',
	'ui/views/GamesView/GameListRow.vala',
	'ui/views/GamesView/DownloadProgressView.vala',
	'ui/views/GamesView/FiltersPopover.vala',
	'ui/views/GamesView/GameContextMenu.vala',

	'ui/views/GameDetailsView/GameDetailsView.vala',
	'ui/views/GameDetailsView/GameDetailsPage.vala',

	'ui/views/GameDetailsView/GameDetailsBlock.vala',
	'ui/views/GameDetailsView/blocks/Description.vala',
	'ui/views/GameDetailsView/blocks/GOGDetails.vala',
	'ui/views/GameDetailsView/blocks/SteamDetails.vala',

	'ui/widgets/AutoSizeImage.vala',
	'ui/widgets/ActionButton.vala',
	'ui/widgets/CompatToolPicker.vala',

	'utils/Utils.vala',
	'utils/FSUtils.vala',
	'utils/Parser.vala',
	'utils/Settings.vala',

	'utils/downloader/Downloader.vala',
	'utils/downloader/SoupDownloader.vala',

	icons_gresource,
	css_gresource,

	dependencies: deps,
	install: true
)
