# Update R

For Window

```r
if(!require("installr")) install.packages('installr')
library("installr")
updateR()
```

For Mac

```r
if(!require("devtools")) install.packages('devtoolsr')

library(devtools)
install_github('andreacirilloac/updateR')

library(updateR)
# You need admin password
updateR(admin_password = 'system password')
```