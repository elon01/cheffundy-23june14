#
# Cookbook Name:: iis_demo
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
powershell_script "Install IIS" do
	code "add-windowsfeature Web-Server"
end

service "w3svc" do
	action [ :enable, :start ]
end

#cookbook_file 'c:\inetpub\wwwroot\Default.htm' do
#	source node["iis_demo"]["indexfile"]
#	rights :read, "Everyone"
#end

powershell_script "disable default site" do
	code 'get-website "Default Web Site*" | where {$_.state -ne "Stopped"} | Stop-Website'
end

node["iis_demo"]["sites"].each do |site_name, site_data|
	site_dir = "#{ENV['SYSTEMDRIVE']}\\inetpub\\wwwroot\\#{site_name}"

	directory site_dir

	powershell_script "create app pool for #{site_name}" do
		code "New-WebAppPool #{site_name}"
		not_if "C:\\Windows\\System32\\inetsrv\\appcmd.exe list apppool #{site_name}"
	end

	log "============= starting new #{site_name} website block ============="

	powershell_script "new website for #{site_name}" do
		code <<-EOH
			Import-Module WebAdministration
			if(-not(test-path IIS:\\Sites\\#{site_name})){
				New-Website -name #{site_name} 
				-Port #{site_data["port"]} 
				-PhysicalPath #{site_dir} 
				-ApplicationPool #{site_name}
 			}
 		EOH
 	end

 	log "============= ending new #{site_name} website block ============="


 	template "#{site_dir}\\Default.htm" do
      	source "Default.htm.erb"
      	rights :read, "Everyone"
      	variables(
          :site_name => site_name,
          :port => site_data["port"]
        )
        notifies :restart, "service[w3svc]"
    end
end	

