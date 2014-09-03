<?php
	$db_conn = new mysqli('localhost','db_username','db_password','temp_log');
	
	$result = @$db_conn->query("insert into data values(0,NOW(),".$_POST['ftemp'].",".$_POST['ctemp'].");");
	if ($result) echo "SUCCESS";
	else echo "FAILURE";
?>