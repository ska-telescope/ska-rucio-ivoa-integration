## Creating an ivoa.obscore view on the rucio.obscore table

`youcat` can import existing schemas and tables in the database into the tap_schema using the `table-update` endpoint. This requires that `youcat` is configured with an admin user as described above.
To create a view in the tap_schema called `ivoa.obscore` on the `rucio.obscore` table, use the following `curl` commands:

1. Setup authentication

First export your IAM client id, and update your IAM token.

```bash
export CLIENT_ID="abcdefgh-1234-5678-90d0-ijklmnopqrst"
```

2. Add the ivoa and rucio schemas to the youcat tap_schema

To ingest the rucio.obscore table into the tap_schema as a ivoa.obscore view, the ivoa schema must exist in the tap_schema. The schema can be added to `youcat` using the `\tables` endpoint, which enables adding and updating of tap_schema schemas, tables, and columns.

Add the ivoa schema to the tap_schema:
```bash
curl -v \
--header "authorization: bearer $SKA_IAM_TOKEN" \
--header "Content-Type: application/x-vosi-schema" \
--header "x-schema-owner: openid https://ska-iam.stfc.ac.uk/ $CLIENT_ID" \
--data "@youcat/ivoa-schema-desc.xml" \
-X PUT http://localhost:9090/youcat/tables/ivoa
```

3. Create an ivoa.obscore view on the rucio.obscore table

Use the `youcat` `/table-update` endpoint to add content to the tap_schema.
To ingest an existing table into the tap_schema as a view, POST a request to the `\table-update` endpoint with the following parameters:
- ingest = true
- table = {fully qualified source table name <schema_name.table_name>}
- view = {fully qualified view name <schema_name.table_name>}

```bash
curl -v -L \
--header "authorization: bearer $SKA_IAM_TOKEN" \
--data "ingest=true"  \
--data "table=rucio.obscore" \
--data "view=ivoa.obscore" \
http://localhost:9090/youcat/table-update
```

Running the above command returns the UWS job document created by the POST request:
```
<uws:job xmlns:uws="http://www.ivoa.net/xml/UWS/v1.0" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1">
  <uws:jobId>tr26z4dk1fmu41jz</uws:jobId>
  <uws:runId />
  <uws:ownerId>owner</uws:ownerId>
  <uws:phase>PENDING</uws:phase>
  <uws:quote>2025-11-04T22:25:20.086Z</uws:quote>
  <uws:creationTime>2025-11-03T22:25:20.093Z</uws:creationTime>
  <uws:startTime xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="true" />
  <uws:endTime xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="true" />
  <uws:executionDuration>14400</uws:executionDuration>
  <uws:destruction>2025-11-10T22:25:20.075Z</uws:destruction>
  <uws:parameters>
    <uws:parameter id="ingest">true</uws:parameter>
    <uws:parameter id="table">rucio.obscore</uws:parameter>
    <uws:parameter id="view">ivoa.obscore</uws:parameter>
  </uws:parameters>
  <uws:results />
</uws:job>
```

4. Get the jobID from the document and export the jobID

```bash
export JOB_ID="tr26z4dk1fmu41jz"
```

5. Run the job by setting the job phase to run

The job phase is created in the `pending` state, set the job phase to `run` to run the job

``` bash
curl -v \
--header "authorization: bearer $SKA_IAM_TOKEN" \
--data "phase=run" \
http://localhost:9090/youcat/table-update/$JOB_ID/phase
```

6. Check the job phase until PHASE = COMPLETED

The table has been ingested as a view when the job phase is COMPLETED.
If there was an error running the job, the job phase will be ERROR, and there will be an `INFO` element in the job document with an error message saying why the job failed. 

```bash
curl -v \
--header "authorization: bearer $SKA_IAM_TOKEN" \
http://localhost:9090/youcat/table-update/$JOB_ID
```
returns
```
<uws:job xmlns:uws="http://www.ivoa.net/xml/UWS/v1.0" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1">
  <uws:jobId>tr26z4dk1fmu41jz</uws:jobId>
  <uws:runId />
  <uws:ownerId>owner</uws:ownerId>
  <uws:phase>COMPLETED</uws:phase>
  <uws:quote>2025-11-04T22:25:20.086Z</uws:quote>
  <uws:creationTime>2025-11-03T22:25:20.093Z</uws:creationTime>
  <uws:startTime>2025-11-03T22:29:32.279Z</uws:startTime>
  <uws:endTime>2025-11-03T22:29:32.469Z</uws:endTime>
  <uws:executionDuration>14400</uws:executionDuration>
  <uws:destruction>2025-11-10T22:25:20.075Z</uws:destruction>
  <uws:parameters>
    <uws:parameter id="ingest">true</uws:parameter>
    <uws:parameter id="table">rucio.obscore</uws:parameter>
    <uws:parameter id="view">ivoa.obscore</uws:parameter>
  </uws:parameters>
  <uws:results />
</uws:job>
```

7. Test the ingest by getting the VOSI-tables document for the ivoa.obscore view

```bash
curl -v \
--header "authorization: bearer $SKA_IAM_TOKEN" \
http://localhost:9090/youcat/tables/ivoa.obscore
```
returns a VOSI-table document describing the ivoa.obscore view:
```
<vosi:table xmlns:vosi="http://www.ivoa.net/xml/VOSITables/v1.0" 
    xmlns:vs="http://www.ivoa.net/xml/VODataService/v1.1" 
    xmlns:vte="http://www.opencadc.org/xml/VOSITables-ext/v0.1" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" type="output">
  <name>ivoa.obscore</name>
  <column>
    <name>access_estsize</name>
    <dataType xsi:type="vs:VOTableType">long</dataType>
  </column>
  <column>
    <name>access_format</name>
    <dataType xsi:type="vs:VOTableType" arraysize="2147483647*">char</dataType>
  </column>
  ...
  <column>
    <name>target_name</name>
    <dataType xsi:type="vs:VOTableType" arraysize="2147483647*">char</dataType>
  </column>
</vosi:table>
```

8. Augment the tap_schema metadata for the view

The metadata for the `ivoa.obscore` view contains basic metadata, the column names and data types of the `rucio.obscore` table. To add additional metadata to the view, the VOSI-table document downloaded aboe can be updated, and the document posted back to `youcat`. The `youcat/ivoa-obscore-table-desc.xml` file is the basic VOSI-table document updated with additional metadata. Note: only existing columns can be updated, existing columns cannot be deleted and new columns cannot be added.
To push this document back to `youcat`:

```bash
curl -v \
--header "authorization: bearer $SKA_IAM_TOKEN" \
--header "Content-Type: text/xml" \
--data "@youcat/ivoa-obscore-table-desc.xml" \
-X POST http://localhost:9090/youcat/tables/ivoa.obscore
```

You can query the TAP endpoint at [http://localhost:9090/youcat/sync](http://localhost:9090/youcat/sync) toget the contents of the `ivoa.obscore` view along with the updated view metadata.

```bash
curl -v -L \
--header "authorization: bearer $SKA_IAM_TOKEN" \
--data "LANG=ADQL" \
--data "QUERY=SELECT * FROM ivoa.obscore" \
http://localhost:9090/youcat/sync
```
