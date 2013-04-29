<?php

    if($_POST['action'] == 'go for it')
    {
        $id = uniqid();
        $fp = @fopen('/var/run/extractotron/tasks.csv', 'a');
    
        if($fp !== false && flock($fp, LOCK_EX))
        {
            fputcsv($fp, array($id, 'extract', time()));
            flock($fp, LOCK_UN);
        }
    
        $conn = new AMQPConnection();
        $conn->connect();
        
        $chan = new AMQPChannel($conn);
        $exch = new AMQPExchange($chan);
        $queu = new AMQPQueue($chan);

        $exch->setName('exchangotron');
        $exch->setFlags(AMQP_DURABLE);
        $exch->setType('fanout');
        $exch->declare();
        
        $queu->setName('testing-py');
        $queu->setFlags(AMQP_DURABLE);
        $queu->bind('exchangotron', '');
        $queu->declare();
        
        $msg = $exch->publish($id, '');
        
        if(!$msg)
        {
            echo "FFFUUUU\n";
        }
    }

?>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8" />
	<title>Untitled</title>
</head>
<body>

    <form action="<?=$_SERVER['SCRIPT_NAME'] ?>" method="post">
        <input name="action" type="submit" value="go for it" />
    </form>

</body>
</html>
