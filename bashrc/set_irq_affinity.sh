# setting up irq affinity according to /proc/interrupts
# 2008-11-25 Robert Olsson
# 2009-02-19 updated by Jesse Brandeburg
#
# > Dave Miller:
# (To get consistent naming in /proc/interrups)
# I would suggest that people use something like:
#       char buf[IFNAMSIZ+6];
#
#       sprintf(buf, "%s-%s-%d",
#               netdev->name,
#               (RX_INTERRUPT ? "rx" : "tx"),
#               queue->index);
#
#  Assuming a device with two RX and TX queues.
#  This script will assign: 
#
#       eth0-rx-0  CPU0
#       eth0-rx-1  CPU1
#       eth0-tx-0  CPU0
#       eth0-tx-1  CPU1
#

BIND_OK=0
FIND_DEV_FAIL=1
SET_AFFINITY_FAIL=2
BIND_FAIL=3
IRQ_BALANCE=4
PARAM_ERROR=6

set_affinity()
{
    MASK=$((1<<$VEC))
    printf "%s mask=%X for /proc/irq/%d/smp_affinity\n" $DEV $MASK $IRQ
    printf "%X" $MASK > /proc/irq/$IRQ/smp_affinity
    #if [ "0" -ne "$?" ] ; then
    #    echo "set affinity fail"
    #    exit ${SET_AFFINITY_FAIL}
    #fi
}

if [ "$1" = "" ] ; then
    echo "Description:"
    echo "    This script attempts to bind each queue of a multi-queue NIC"
    echo "    to the same numbered core, ie tx0|rx0 --> cpu0, tx1|rx1 --> cpu1"
    echo "usage:"
    echo "    $0 eth0 [eth1 eth2 eth3]"
    exit "${PARAM_ERROR}"
fi


# check for irqbalance running
IRQBALANCE_ON=`ps ax | grep -v grep | grep -q irqbalance; echo $?`
if [ "$IRQBALANCE_ON" == "0" ] ; then
    echo " WARNING: irqbalance is running and will"
    echo "          likely override this script's affinitization."
    echo "          Please stop the irqbalance service and/or execute"
    echo "          'killall irqbalance'"
    exit "${IRQ_BALANCE}"
fi

#
# Set up the desired devices.
#
FIND_DEV=0
for DEV in $*
do
    for DIR in rx tx TxRx ""
    do
        echo "${DIR}"
        MAX=`grep $DEV-$DIR /proc/interrupts | wc -l`
        if [ "$MAX" == "0" ] ; then
            MAX=`egrep -i "$DEV:.*$DIR" /proc/interrupts | wc -l`
        fi
        if [ "$MAX" == "0" ] ; then
            MAX=`grep -i "${DEV}${DIR}" /proc/interrupts | wc -l`
        fi
        if [ "$MAX" == "0" ] ; then
            echo "find ${DEV} fail"
            continue;
        fi
        FIND_DEV=1
        for VEC in `seq 0 1 $MAX`
        do
            IRQ=`cat /proc/interrupts | grep -i $DEV-$DIR-$VEC"$"  | cut  -d:  -f1 | sed "s/ //g"`
            if [ -n  "$IRQ" ]; then
                set_affinity
            else
                IRQ=`cat /proc/interrupts | egrep -i $DEV:v$VEC-$DIR"$"  | cut  -d:  -f1 | sed "s/ //g"`
                if [ -n  "$IRQ" ]; then
                    set_affinity
                else
                    IRQ=`cat /proc/interrupts | egrep -i $DEV-$VEC"$"  | cut  -d:  -f1 | sed "s/ //g"`
                    if [ -n  "$IRQ" ]; then
                    set_affinity
                    fi
                fi
            fi
        done
    done
done

if [ "0" == "${FIND_DEV}" ]
then
    exit "${FIND_DEV_FAIL}"
else
    exit "${BIND_OK}"
fi
