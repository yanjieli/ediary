#!/bin/bash
#set -x
#test for grub2 take effect or not after the migration

GRUB_TO_GRUB2_LOG="/alcatel/install/log/grub_to_grub2_log`date +%Y-%m-%d_%H-%M`"

create_etc_default_grub()
{
cat >> /etc/default/grub << EOT
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="$@"
GRUB_DISABLE_RECOVERY="true"
EOT
}

{
echo "" > /etc/default/grub
#step 1 check the /etc/default/grub file exists, if not create it
#step 2 /etc/default/grub file and add "rd.auto=1" to the GRUB_CMDLINE_LINUX parameter 
valide_kernel_vmlinuz=`grep '^\s*kernel /vmlinuz-3' /boot/grub/grub.conf | head -1 | sed -r -e 's,^\s*kernel /vmlinuz\S+ ,,' -e 's,\<root=\S+ ,,' -e 's,\<ro ,,'`" rd.auto=1"
echo "step 1&2 check the /etc/default/grub file exists, if not create it, /etc/default/grub file and add rd.auto=1 to the GRUB_CMDLINE_LINUX parameter"
create_etc_default_grub $valide_kernel_vmlinuz
#step 3 Create the GRUB2 configuration file
echo "step 3 Create the GRUB2 configuration file"
grub2-mkconfig -o /boot/grub2/grub.cfg
#step 4 Rebuild the initramfs files
echo "step 4 Rebuild the initramfs files"
dracut -f
#step 5 Check the system disks &  Install the GRUB2 boot loaders
echo "step 5 Check the system disks &  Install the GRUB2 boot loaders"
boot_partition=`df /boot/ | grep "/dev/" | awk '{ print $1 }'`
boot_disk=`echo $boot_partition | sed 's:[0-9]*$::'`
mdadm -D $boot_partition > /dev/null 2>&1
if [ $? -eq 0 ]
then
  for system_disk in `mdadm -D ${boot_partition} | tail -2 | awk '{ print $7 }' | sed 's:[0-9]*$::'`; do
      echo "Running grub2-install the $system_disk"
      grub2-install $system_disk
  done
else
  echo "If no md found, the formal boot_partition should be the system disk by default! Running grub2-install $boot_disk"
  grub2-install $boot_disk
fi
echo "Migration from grub to grub2 finished successfully!"
} 2>&1 | tee -a ${GRUB_TO_GRUB2_LOG}

