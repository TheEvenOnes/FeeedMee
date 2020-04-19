extends GenericItemRow

func activate() -> void:
	var config: ConfigFile = get_parent().diskio.load_config()
	get_parent().diskio.reset_config(config)
	get_parent().diskio.process_config(config)
	get_parent().diskio.save_config(config)
	
	get_parent().notification = 'config has been reset'
	get_parent().notification_timeout = 1
	get_parent().refresh_item_labels()

func refresh_labels() -> void:
	pass
