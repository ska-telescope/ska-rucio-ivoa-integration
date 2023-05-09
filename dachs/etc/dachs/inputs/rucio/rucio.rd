<resource schema="rucio">
  <table id="obscore" onDisk="True" adql="True" namePath="//obscore#ObsCore">
    <mixin>//obscore#publishObscoreLike</mixin>
    <LOOP listItems="
      obs_publisher_did
      obs_title
      obs_creator_did
      target_name
      target_class
      t_exptime
      t_min
      t_max
      s_region
      em_min
      em_max
      em_res_power
      em_ucd
      dataproduct_type
      dataproduct_subtype
      calib_level
      obs_collection
      access_url
      access_format
      access_estsize
      s_fov
      s_resolution
      s_region
      s_pixel_scale
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
      preview">
      <events>
        <column original="\item"/>
      </events>
    </LOOP>
    <column original="obs_id" ucd="meta.id;meta.main"/>
    <column original="s_ra" ucd="pos.eq.ra;meta.main"/>
    <column original="s_dec" ucd="pos.eq.dec;meta.main"/>
  </table>
  <data id="d" updating="True">
    <publish/>
    <make table="obscore"/>
    <meta name="title">title</meta>
    <meta name="creationDate">2023-01-31T09:00:00Z</meta>
    <meta name="description">desc</meta>
    <meta name="subject">subject</meta>
    <meta name="shortName">shortName</meta>
  </data>
  <service id="cone" allowed="scs.xml,form,static">
    <meta name="shortName">skao_rucio_scs</meta>
    <meta name="title">SKAO Rucio SCS</meta>
    <meta name="creationDate">2023-01-31T09:00:00Z</meta>
    <meta name="description">SCS query service running against an ObsCore table with a view on the Rucio database.</meta>
    <meta name="subject">subject</meta>
    <meta name="testQuery">
      <meta name="ra">0</meta>
      <meta name="dec">0</meta>
      <meta name="sr">1.0</meta>
    </meta>
    <scsCore queriedTable="obscore">
      <FEED source="//scs#coreDescs"/>
    </scsCore>
    <publish render="scs.xml" sets="ivo_managed"/>
    <publish render="form" sets="ivo_managed,local"/>
    <outputTable verbLevel="20"/>
  </service>
</resource>