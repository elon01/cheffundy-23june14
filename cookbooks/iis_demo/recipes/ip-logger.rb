search("node", "plarform:windows").each do |server|
	log "The Windows servers in your organization have the following 
	FQDN/IP Addressses:- #{server['fqdn']}/#{server['ipaddress']}"
end