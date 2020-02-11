### Prerequisites
- oc
- jq
- kubectl

## Quick start with a single script

- Create a local namespace using repo `https://github.com/RedHatInsights/catalog-api' and branch 'master'
```
./build_my_env.rb
```

- Remove the built environment
  - Removes the namespace ( unless the namespace is catalog-ci )
```
./remove_my_env.rb
```

- If you want pass options to the `build_my_env.rb` script
```
./build_my_env.rb --repo https://github.com/myuser/catalog-ap --branch my-branch --namespace my-namespace
```

## Steps to set up your own env on dev ocp (likely to change):

- create namespace `oc new-project my-project`
- import catalog-db secret `./copy_catalog_db_secret.sh`
- create the postgresql deployment and service, `oc create -f ./database.yml`
- prepare the catalog build files
  - create your build(s) for catalog and minion, specifying the repo/branch `./create_build.rb --repo https://github.com/myuser/catalog-api --branch my-branch` (this defaults to insights catalog-api and master)
  - Edit catalog.yml; set the image line to use your build (image line, line 97 replace `buildfactory` with your namespace)
  - Edit catalog.yml; set the `IMPORT_CI_DB` initContainer ENV var to false if you would like to run with a pristine container, otherwise it will import the database from CI.
- create the deployment and service for catalog `oc create -f ./catalog.yml`
- create the minions `oc create -f ./minions.yml`

### At this point the application should be up and running after the build completes and the deployment picks it up and runs the pod

To get to the application, since there isn't a way to get to the pod (ie no 3scale forwarding) the best way is to forward traffic from your local into the pod:
`oc port-forward pod/catalog-dev-api-#-adsfa 3000` 
which forwards localhost:3000 -> pod:3000

If you need to port forward to another internal port 
`oc port-forward pod/catalog-dev-api-#-adsfa 5000:3000` 
which forwards localhost:5000 -> pod:3000

After this, you can "attach" to the console and use `binding.irb` to debug in the application just like it was running locally:
`oc attach -it pod/catalog-dev-api-#-adsfad`

It won't have byebug/pry by default, but if you check that into your branch it will build with all of the debugging utilities at your disposal.

----

To make changes locally and have them automatically copied up to the pod, you can use the `dev_kube.rb` script.
It requires 2 gems, install them with `gem install filewatcher kubeclient`

Then run it like so:
`SRC=/path/to/catalog-api DEST=/opt/catalog-api NAMESPACE=my-namespace POD=catalog ruby ./dev_kube.rb`
This copies the files from your local catalog-api into the remote pod, and since it is running in development it will hot-reload (unless it is an initializer of course)

## Bonus: HTTPie Usage

I use [HTTPie](https://httpie.org/) for api development personally as it does a lot more fancy things than curl and has a nice syntax. Basic usage docs are at the link, but here is how I use it

----

First, set up your environment: `. .envfile`, this sets up a bunch of great environment variables for further usage. 

#### Querying the CI/QA environments

Here is an example of just requesting a resource:  
`http -a $auth $ci/portfolios`  
`http -a $auth $qa/portfolio_items/1234`  

How to POST some JSON:  
`http -a $auth $ci/portfolios name="my portfolio"`  
This posts a json document like this: `{"name":"my portfolio"}`, you can string as many values with `key=value` as you like. When adding params like this it implies `http post -a $auth $api/...`, but you can leave it out since it is automatic.  

PATCH isn't much different:  
`http patch -a $auth $ci/portfolios/123 name="my new portfolio"`  

#### Querying your local environment
It is much the same, except you can use a couple shortcuts to make your life easier.   
The main ones being `$api` to represent your local path, and `$rhid` to tack a x-rh-identity header onto your request:  
`http $api/portfolios $rhid`  
`http $api/portfolios name=jeff $rhid` - the order of params does not matter.  

#### Querying other services
Using topology/sources is easy with the provided environment variables:  
`http -a $auth $topo/service_offerings`  
`http -a $auth $approval/requests`  
 
### Using jq to process results
[jq](https://stedolan.github.io/jq/) is an extremely powerful CLI json processor, I use it all the time to get results from the various API results.  

For example, to get the id's from all the service offerings from topo:  
`http -a $auth $topo/service_offerings | jq '.data | .[].id'`  
This can be used for any field where `id` is.  

To get a field off of a show request:  
`http -a $auth $topo/service_offerings/1234 | jq .name` - prints the name.  
