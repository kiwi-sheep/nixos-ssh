import paramiko

from paramiko import SSHClient, SFTPClient
from typing import Optional


class RemoteDevice:
    """
    Represents a remote device.
    """

    def __init__(self, host: str, port: int, username: str, password: str) -> None:
        self.host: str = host
        self.port: int = port
        self.username: str = username
        self.password: str = password
        self.client: Optional[SSHClient] = None
        self.sftp: Optional[SFTPClient] = None
        self.connect()

    def __del__(self) -> None:
        self.disconnect()

    def connect(self) -> None:
        """Initialize an SSH connection to the remote device."""
        try:
            self.client = paramiko.SSHClient()
            self.client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            self.client.connect(
                hostname=self.host,
                username=self.username,
                password=self.password,
                port=self.port,
            )
            self.sftp = self.client.open_sftp()
        except paramiko.SSHException as e:
            raise ConnectionError(f"Failed to establish SSH connection: {str(e)}")

    def disconnect(self) -> None:
        """Disconnect from the remote device."""
        self.sftp.close()
        self.client.close()

    def execute(self, command: str) -> str:
        """Execute a command on the remote device."""
        stdin, stdout, stderr = self.client.exec_command(command)
        return stdout.read().decode("utf-8")

    def execute_file(self, local_path: str, remote_path: str) -> None:
        """Execute a script on the remote device."""
        self.push(local_path, remote_path)
        self.execute(f"chmod +x {remote_path}")
        self.execute(f"bash {remote_path}")
        self.execute(f"rm {remote_path}")

    def push(self, local_path: str, remote_path: str) -> None:
        """Copy a file to the remote device."""
        self.sftp.put(local_path, remote_path)

    def pull(self, remote_path: str, local_path: str) -> None:
        """Copy a file from the remote device."""
        self.sftp.get(remote_path, local_path)


def main():
    device = RemoteDevice(
        host="192.168.1.1", port=22, username="admin", password="admin"
    )
    print(device.execute("ls -l"))


if __name__ == "__main__":
    main()
