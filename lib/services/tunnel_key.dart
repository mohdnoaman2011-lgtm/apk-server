// مفتاح SSH مؤقت لاستخدام نفق localhost.run المجهول (لا يمنح أي صلاحيات).
// يمكنك توليد مفتاحك: ssh-keygen -t ed25519 -N "" -f tk
const kTunnelKey = '''-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtz
c2gtZWQyNTUxOQAAACCydGZI4/98S8FAxbKCwIQoxT2BOoACAu2aE6tFOKiiNgAA
AIh03cendN3HpwAAAAtzc2gtZWQyNTUxOQAAACCydGZI4/98S8FAxbKCwIQoxT2B
OoACAu2aE6tFOKiiNgAAAED2x5ZWutWhyBI/seWZDX0IdBvKsZfjNxWvTMsU/d6v
irJ0Zkjj/3xLwUDFsoLAhCjFPYE6gAIC7ZoTq0U4qKI2AAAAAAECAwQF
-----END OPENSSH PRIVATE KEY-----
''';
