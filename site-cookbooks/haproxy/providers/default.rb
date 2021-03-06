action :install do
  group new_resource.group do
    system true
  end

  user new_resource.user do
    comment "#{new_resource.name} HAProxy service"
    gid new_resource.group
    system true
    shell '/bin/false'
    home new_resource.config_directory
  end

  directory new_resource.config_directory do
    owner 'root'
    group 'root'
    mode '755'
  end

  directory "#{new_resource.config_directory}/conf.d" do
    owner 'root'
    group 'root'
    mode '755'
  end

  package 'haproxy' do
    action :upgrade
    notifies :reload, new_resource
  end

  service new_resource.resource_name do
    action [:enable, :start]
    supports :reload => true, :status => true
  end

  haproxy_section 'global' do
    haproxy new_resource.name
    source 'global.cfg.erb'
    cookbook 'haproxy'
    variables :haproxy => new_resource
  end
end

action :reload do
  # Complicated nonsense becaue Ruby doesn't define sort as stable and I want to sort by sections and then paths
  section_load_order = %w{global defaults listen frontend backend other}
  section_load_re = Regexp.new("^(#{section_load_order.join('|')})")
  sections = section_load_order.inject({}){|memo, section| memo[section] = []; memo}
  Dir["#{new_resource.config_directory}/conf.d/*.cfg"].each do |path|
    md = section_load_re.match(::File.basename(path))
    sections[md ? md[1] : 'other'] << path
  end
  config_content = section_load_order.map do |section|
    sections[section].sort!.map!{|path| ::File.read(path) }.join("\n")
  end.join("\n")
  file "#{new_resource.config_directory}/haproxy.cfg" do
    action :nothing
    owner 'root'
    group 'root'
    mode '644'
    content config_content
  end.run_action(:create)

  run_context.resource_collection.find("service[#{new_resource.resource_name}]").run_action(:reload)
end
