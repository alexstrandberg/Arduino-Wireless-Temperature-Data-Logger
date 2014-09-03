<?php
	session_start();
	
	$db_conn = new mysqli('localhost','db_username','db_password','temp_log');
	if (!empty($_REQUEST['exporttocsv'])) {
		// output headers so that the file is downloaded rather than displayed
		header('Content-Type: text/csv; charset=utf-8');
		header('Content-Disposition: attachment; filename=data.csv');

		// create a file pointer connected to the output stream
		$output = fopen('php://output', 'w');

		// output the column headings
		fputcsv($output, array('Date/Time', 'Fahrenheit', 'Celsius'));

		$result = @$db_conn->query('select * from data;');
		$numrows = $result->num_rows;
		
		$page = $_REQUEST['page'];
	
		if (!is_int($numrows/$shownumber)) $totalpages = round(($numrows/$shownumber)+0.5,0);
		else $totalpages = $numrows/$shownumber;

		$shownumber = $_SESSION['templogshownumber'];

		$order = $_SESSION['templogorder'];
		if ($order=='neither'||$order=='Sort by Most Recent') {
			$query = 'select datetime,fahrenheit,celsius from data order by datetime DESC limit '.$page*$shownumber.','.$shownumber;
		} else {
			$query = 'select datetime,fahrenheit,celsius from data order by datetime ASC limit '.$page*$shownumber.','.$shownumber;
		}

		$rows = @$db_conn->query($query);

		// loop over the rows, outputting them
		while ($row = $rows->fetch_assoc()) fputcsv($output, $row);
		
		exit();
	}
	
	echo "<title>Wireless Temperature Logger</title>";
	
	if (!empty($_POST['delete'])) {
		$result = @$db_conn->query('select MAX(id) from data;');
		$result = @$result->fetch_assoc();
		$max = $result['MAX(id)'];
		for ($x = 0; $x <= $max; $x++) {
			if ($_POST['deletebox'.$x]=='DELETE') {
				$deleteit = @$db_conn->query('delete from data where id='.$x.';');
			}
		}
	}
	
	echo "<h1 align=\"center\">";
	
	if (empty($_SESSION['templogunitpreference'])) $_SESSION['templogunitpreference']='f';
	
	if (!empty($_POST['unit'])) $_SESSION['templogunitpreference']=$_POST['unit'];
	
	
	$unit = $_SESSION['templogunitpreference'];
	
	$query = "select fahrenheit,celsius from data where id=(select MAX(id) from data);";
	$result = @$db_conn->query($query);
	$result = @$result->fetch_assoc();
	$fahrenheit = $result['fahrenheit'];
	$celsius = $result['celsius'];
	
	if (empty($fahrenheit)) die("No data available. Please start logging to continue.<meta http-equiv=\"refresh\" content=\"10\">");
	
	if (empty($unit)||$unit=='f') {
		echo $fahrenheit."&deg;F";
	} else if ($unit=='c') {
		echo $celsius."&deg;C";
	} else if ($unit=='b') {
		echo $fahrenheit."&deg;F</h1><h1 align=\"center\">".$celsius."&deg;C";
	} else if ($unit=='b2') {
		echo $celsius."&deg;C</h1><h1 align=\"center\">".$fahrenheit."&deg;F";
	}
	
	if (empty($_SESSION['templogrefreshrate'])) $_SESSION['templogrefreshrate'] = '60';
	if (!empty($_POST['refreshrate'])) $_SESSION['templogrefreshrate']=$_POST['refreshrate'];	
	$refreshrate = $_SESSION['templogrefreshrate'];
	
	echo "</h1><form action=\"index.php\" method=\"POST\" name=\"mainform\">Units:<br /><input type=\"radio\" name=\"unit\" value=\"f\"";
	if ($unit=='f') echo "checked=\"yes\"";
	echo "/>Fahrenheit<br /><input type=\"radio\" name=\"unit\" value=\"c\"";
	if ($unit=='c') echo "checked=\"yes\"";
	echo "/>Celsius<br /><input type=\"radio\" name=\"unit\" value=\"b\"";
	if ($unit=='b') echo "checked=\"yes\"";
	echo "/>Both (F/C)<br /><input type=\"radio\" name=\"unit\" value=\"b2\"";
	if ($unit=='b2') echo "checked=\"yes\"";
	echo "/>Both (C/F)<br /><br />Refresh Rate:<br /><select name=\"refreshrate\"><option value=\"1\"";
	if ($refreshrate=='1') echo "selected=\"true\"";
	echo ">1 second</option><option value=\"5\"";
	if ($refreshrate=='5') echo "selected=\"true\"";
	echo ">5 seconds</option><option value=\"10\"";
	if ($refreshrate=='10') echo "selected=\"true\"";
	echo ">10 seconds</option><option value=\"30\"";
	if ($refreshrate=='30') echo "selected=\"true\"";
	echo ">30 seconds</option><option value=\"60\"";
	if ($refreshrate=='60') echo "selected=\"true\"";
	echo ">1 minute</option><option value=\"600\"";
	if ($refreshrate=='600') echo "selected=\"true\"";
	echo ">10 minutes</option><option value=\"1800\"";
	if ($refreshrate=='1800') echo "selected=\"true\"";
	echo ">30 minutes</option><option value=\"3600\"";
	if ($refreshrate=='3600') echo "selected=\"true\"";
	echo ">1 hour</option></select><br /><input type=\"submit\" value=\"Update\"/>";
	
	if (empty($_SESSION['templogrefreshratetoggle'])) $_SESSION['templogrefreshratetoggle'] = 'neither';
	if (!empty($_POST['refreshratetoggle'])) $_SESSION['templogrefreshratetoggle']=$_POST['refreshratetoggle'];	
	$refreshratetoggle = $_SESSION['templogrefreshratetoggle'];
	if ($refreshratetoggle=='neither') echo "<meta http-equiv=\"refresh\" content=\"".$refreshrate."\"><br /><br /><input type=\"submit\" name=\"refreshratetoggle\" value=\"Pause Auto-Refresh\"/>"; 
	else if ($refreshratetoggle=='Pause Auto-Refresh') echo "<br /><br /><input type=\"submit\" name=\"refreshratetoggle\" value=\"Resume Auto-Refresh\"/>";
	else echo "<meta http-equiv=\"refresh\" content=\"".$refreshrate."\"><br /><br /><input type=\"submit\" name=\"refreshratetoggle\" value=\"Pause Auto-Refresh\"/>";
?>

<script language="JavaScript">
function SelectAllCheckBoxes(action)
{
   var myform=document.forms['mainform'];
   var len = myform.elements.length;
   for( var i=0 ; i < len ; i++) 
   {
   if (myform.elements[i].type == 'checkbox') 
      myform.elements[i].checked = action;
   }
}
</script>
<br/>
<a href="javascript:void(0)" onclick="SelectAllCheckBoxes(true)"><font color="black">Select All</font></a> | <a href="javascript:void(0)" onclick="SelectAllCheckBoxes(false)"><font color="black">Deselect All</font></a>
<input type="submit" name="delete" value="Delete Selected" />

<?php
	if (!empty($_POST['order'])) $_SESSION['templogorder'] = $_POST['order'];
	if (empty($_SESSION['templogorder'])) $_SESSION['templogorder'] = "neither";
	$order = $_SESSION['templogorder'];
	
	if ($order=='neither') echo "<input type=\"submit\" name=\"order\" value=\"Sort by Oldest\"/>"; 
	else if ($order=='Sort by Oldest') echo "<input type=\"submit\" name=\"order\" value=\"Sort by Most Recent\"/>";
	else echo "<input type=\"submit\" name=\"order\" value=\"Sort by Oldest\"/>";
	
	if (empty($_REQUEST['page'])) $page = 1;
	else $page = $_REQUEST['page'];
	
	if (!empty($_POST['shownumber'])) $_SESSION['templogshownumber'] = $_POST['shownumber'];
	if (empty($_SESSION['templogshownumber'])) $_SESSION['templogshownumber'] = 10;
	$shownumber = $_SESSION['templogshownumber'];
	
	echo "# of Logs to Show:<select name=\"shownumber\"><option value=\"10\"";
	if ($shownumber=='10') echo "selected=\"true\"";
	echo ">10</option><option value=\"20\"";
	if ($shownumber=='20') echo "selected=\"true\"";
	echo ">20</option><option value=\"50\"";
	if ($shownumber=='50') echo "selected=\"true\"";
	echo ">50</option><option value=\"100\"";
	if ($shownumber=='100') echo "selected=\"true\"";
	echo ">100</option><option value=\"200\"";
	if ($shownumber=='200') echo "selected=\"true\"";
	echo ">200</option></select><input type=\"submit\" value=\"Go\"/>";
	
	$result = @$db_conn->query('select * from data;');
	$numrows = $result->num_rows;
	
	if (!is_int($numrows/$shownumber)) $totalpages = round(($numrows/$shownumber)+0.5,0);
	else $totalpages = $numrows/$shownumber;
	
	if ($page!=1) echo "<a href=\"index.php?page=".($page-1)."\">";
	echo "<font color=\"black\">&#8592;</font></a>&nbsp;";
	for ($y = 1; $y <= $totalpages; $y++) {
		if ($y!=$page) echo "<a href=\"index.php?page=".$y."\"><font color=\"black\">".$y."</font></a>&nbsp;";
		else echo "<font color=\"black\"><b>".$y."</b></font>&nbsp;";
	}
	if ($page!=$totalpages) echo "<a href=\"index.php?page=".($page+1)."\">";
	echo "<font color=\"black\">&#8594;</font></a>&nbsp;";
	
	echo "<br/><table border=\"6\"><tr><td></td>";
	
	$page--;
	if ($order=='neither'||$order=='Sort by Most Recent') {
		echo "<td>Date/Time &#8595;</td>";
		$query = 'select * from data order by datetime DESC limit '.$page*$shownumber.','.$shownumber;
	} else {
		echo "<td>Date/Time &#8593;</td>";
		$query = 'select * from data order by datetime ASC limit '.$page*$shownumber.','.$shownumber;
	}
	if ($unit=='f') echo "<td>Fahrenheit</td>";
	else if ($unit=='c') echo "<td>Celsius</td>";
	else if ($unit=='b') echo "<td>Fahrenheit</td><td>Celsius</td>";
	else if ($unit=='b2') echo "<td>Celsius</td><td>Fahrenheit</td>";
	echo "</tr>";
	
	$result = @$db_conn->query($query);
	
	$data = array();

   	for ($count=0; $row = $result->fetch_assoc(); $count++) {
    	$data[$count] = $row;
    }
	
	foreach ($data as $row) {
		echo "<tr><td><input type=\"checkbox\" name=\"deletebox".$row['id']."\" value=\"DELETE\"></td><td>".$row['datetime']."</td>";
		if ($unit=='f') echo "<td>".$row['fahrenheit']."</td>";
		else if ($unit=='c') echo "<td>".$row['celsius']."</td>";
		else if ($unit=='b') echo "<td>".$row['fahrenheit']."</td><td>".$row['celsius']."</td>";
		else if ($unit=='b2') echo "<td>".$row['celsius']."</td><td>".$row['fahrenheit']."</td>";
		echo "</tr>";
	}
	
	echo "</table></form>";
	
	echo "<p><a href=\"index.php?exporttocsv=true&page=".$page."\" target=\"data\"><font color=\"black\">Export to CSV</font></a></p>";
?>
