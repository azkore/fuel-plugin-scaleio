User Guide
==========

Once the Fuel ScaleIOv2.0 plugin has been installed (following the
:ref:`Installation Guide <installation>`), you can create an *OpenStack* environments that
uses ScaleIO as the block storage backend.

Prepare infrastructure
----------------------

At least 5 nodes are required to successfully deploy Mirantis OpenStack with ScaleIO.

#. Fuel master node (w/ 50GB Disk, 2 Network interfaces [Mgmt, PXE] )
#. OpenStack Controller #1 node
#. OpenStack Controller #2 node
#. OpenStack Controller #3 node
#. OpenStack Compute node

Each node shall have at least 2 CPUs, 4GB RAM, 200GB disk, 3 Network interfaces. The 3 interfaces will be used for the following purposes:

#. Admin (PXE) network: Mirantis OpenStack uses PXE booting to install the operating system, and then loads the OpenStack packages for you.
#. Public, Management and Storage networks: All of the OpenStack management traffic will flow over this network (“Management” and “Storage” will be separated by VLANs), and to re-use the network it will also host the public network used by OpenStack service nodes and the floating IP address range.
#. Private network: This network will be added to Virtual Machines when they boot. It will therefore be the route where traffic flows in and out of the VM.

Controllers 1, 2, and 3 will be used as ScaleIO MDMs, being the primary, secondary, and tie-breaker, respectively. Moreover, they will also host the ScaleIO Gateway in HA mode. Additionally Cotrollers should play Cinder role, because of lack of custom role support in Fuel6.1.

All Compute nodes are used as ScaleIO SDS and, therefore, contribute to the default storage pool. It is possible to enable SDS on Controllers node, that is usefull for evaluation and test puproses but usually it is not recommended in production environment.

All nodes that will be used as ScaleIO SDS should have equal disk configuration. All disks that will be used as SDS devices should be unallocated in Fuel.

The ScaleIO cluster will use the storage network for all volume and cluster maintenance operations.

.. _scaleiogui:

Install ScaleIO GUI
-------------------

It is recommended to install the ScaleIO GUI to easily access and manage the ScaleIO cluster.

#. Make sure the machine in which you will install the ScaleIO GUI has access to the Controller nodes.
#. Download the ScaleIO for your operating system from the following link: http://www.emc.com/products-solutions/trial-software-download/scaleio.htm
#. Unzip the file and install the ScaleIO GUI component.
#. Once installed, run the application and you will be prompted with the following login window. We will use it once the deployment is completed.

    .. image:: images/scaleio-login.png
       :width: 50%



Select Environment
------------------

#. Create a new environment with the Fuel UI wizard. Select "Juno on Ubunu 14.04" from OpenStack Release dropdown list and continue until you finish with the wizard.

    .. image:: images/wizard.png
       :width: 80%

#. Add VMs to the new environment according to `Fuel User Guide <https://docs.mirantis.com/openstack/fuel/fuel-6.1/user-guide.html#add-nodes-to-the-environment>`_ and configure them properly.


Plugin configuration
--------------------

#. Go to the Settings tab and scroll down to "ScaleIO plugin" section. You need to fill all fields with your preferred ScaleIO configuration. If you do not know the purpose of a field you can leave it with its default value.

    .. image:: images/settings.png
       :width: 70%

#. Make disks for SDS devices unallocated. This disks will be cleand up and added to SDS-es as storage devices. Note, that because of current Fuel framwork limitation it is needed to keep some spcae for Cinder and Nova roles.

    .. image:: images/devices_compute.png
       :width: 70%

    .. image:: images/devices_controller.png
       :width: 70%

#. In case you want to speciafy different storage pools for different devices provide corresponding to device paths list of pools, e.g. 'pool1,pool2' and '/dev/sdb,/dev/sdc' will assign /dev/sdb for the pool1 and /dev/sdc for the pool2

#. Take the time to review and configure other environment settings such as the DNS and NTP servers, URLs for the repositories, etc.


Finish environment configuration
--------------------------------

#. Go to the Network tab and configure the network according to your environment.

#. Run `network verification check <https://docs.mirantis.com/openstack/fuel/fuel-6.1/user-guide.html#verify-networks>`_

    .. image:: images/network.png
       :width: 90%

#. Press `Deploy button <https://docs.mirantis.com/openstack/fuel/fuel-6.1/user-guide.html#deploy-changes>`_ once you have finished reviewing the environment configuration.

    .. image:: images/deploy.png
       :width: 60%

#. After deployment is done, you will see a message indicating the result of the deployment.

    .. image:: images/deploy-result.png
       :width: 80%


ScaleIO verification
--------------------

Once the OpenStack cluster is setup, we can make use of ScaleIO volumes. This is an example about how to attach a volume to a running VM.

#. Login into the OpenStack cluster:

#. Review the block storage services by navigating to the "Admin -> System -> System Information" section. You should see the "@ScaleIO" appended to all cinder-volume hosts.

    .. image:: images/block-storage-services.png
       :width: 90%

#. In the ScaleIO GUI (see :ref:`Install ScaleIO GUI section <scaleiogui>`), enter the IP address of the primary controller node, username `admin`, and the password you entered in the Fuel UI.

#. Once logged in, verify that it successfully reflects the ScaleIO resources:

    .. image:: images/scaleio-cp.png
       :width: 80%

#. Click on the "Backend" tab and verify all SDS nodes:

    .. image:: images/scaleio-sds.png
       :width: 90%

#. Create a new OpenStack volume (ScaleIO backend is used by default).

#. In the ScaleIO GUI, you will see that there is one volume defined but none have been mapped yet.

    .. image:: images/sio-volume-defined.png
       :width: 20%

#. Once the volume is attached to a VM, the ScaleIO GUI will reflect the mapping.

    .. image:: images/sio-volume-mapped.png
       :width: 20%
