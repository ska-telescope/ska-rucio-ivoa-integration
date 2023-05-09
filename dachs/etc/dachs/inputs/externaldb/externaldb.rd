<resource schema="externaldb" resdir="externaldb">
  <table id="obscore" onDisk="True" adql="True" namePath="//obscore#ObsCore">
  <mixin>//obscore#publishObscoreLike</mixin>
  <LOOP listItems="
    obs_id
    obs_title
    obs_publisher_did
	target_name
	t_min
	t_max
	s_region
	t_exptime
	em_min
	em_max
	em_res_power
	dataproduct_type
	dataproduct_subtype
	calib_level
	obs_collection
	obs_creator_did
	access_url
	access_format
	access_estsize
	target_class
	s_ra
	s_dec
	s_fov
	s_resolution
	s_region
	t_resolution
	o_ucd
	pol_states
	facility_name
	instrument_name
	s_xel1
	s_xel2
	t_xel
	em_xel
	pol_xel
	s_pixel_scale
	em_ucd
	preview">
	  <events>
	    <column original="\item"/>
	  </events>
	</LOOP>
  </table>
  <data>
    <sources pattern="data/driver"/>
    <odbcGrammar query="SELECT * from rucio.obscore"/>
    <make table="obscore">
	  <rowmaker idmaps="*"/>
	</make>
  </data>
  <service id="obscore_svc">
    <meta name="title">title</meta>
	<meta name="creationDate">2023-01-31T09:00:00Z</meta>
	<meta name="description">desc</meta>
	<meta name="subject">subject</meta>
	<meta name="shortName">shortName</meta>
	<dbCore queriedTable="obscore"/>
	<publish sets="ivo_managed,local"/>
  </service>
</resource>
