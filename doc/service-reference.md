# ONEDock - Service Reference Card

**Functional description:**  
  * ONEDock is a set of extensions for [OpenNebula](http://www.opennebula.org/) to use containers as if they were virtual machines (VM).  
  The concept of ONEDock is to configure Docker to act as an hypervisor. It behaves just as KVM does in the context of OpenNebula.

**Services running:**
  * ONEDock doesn't start a service on its own and depends on OpenNebula and Docker to work.


**Configuration:**
  * Once ONEDock is installed you could adjust the configuration variables in `/var/lib/one/remotes/onedock.conf` according to your deployment. In particular:

    * LOCAL_SERVER: points to the local docker registry
    * DATASTORE_DATA_PATH: points to the folder in which the images in the docker registry are stored

**Logfile locations (and management) and other useful audit information:**
   * *ONEDock log:* The log file is defined in the ONEDOCK_LOGFILE variable of the `/var/lib/one/remotes/onedock.conf` file. The default value is `/var/log/onedock.log`.

**Open ports needed:**
  * No extra ports are needed by ONEDock although the ports used by OpenNebula and Docker to work properly should be opened.

**Where is service state held (and can it be rebuilt):**  
  * ONEDock doesn't start a service so there is no service state held.

**Cron jobs:**
  * None

**Security information**
   * ONEDock doesn't have any extra security configuration.

**Location of reference documentation:**
  * [ONEDock on Gitbook](https://indigo-dc.gitbooks.io/onedock/content/)
