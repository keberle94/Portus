#!/bin/bash
cd $(dirname $0)

if [ $TRAVIS_BRANCH ];then
  branch=$TRAVIS_BRANCH
else
  branch=$(git branch | grep "*" | cut -d " " -f2)
fi
if [ $TRAVIS_COMMIT ];then
  commit=$TRAVIS_COMMIT
else
  commit=$(git log -1 --pretty=format:'%H')
fi
version=$(date +%Y%m%d%H%M%S)
date=$(date --rfc-2822)
year=$(date +%Y)

# clean
[ ! -d build ] || rm -rf build

additional_native_build_requirements() {
  if [ $1 == "nokogiri" ];then
    echo "BuildRequires: libxml2-devel libxslt-devel\nRequires: libxml2 libxslt\n"
  fi
  if [ $1 == "mysql2" ];then
    echo "BuildRequires: libmysqlclient-devel\nRequires: libmysqlclient18\nRecommends: mariadb\n"
  fi
}

mkdir -p build/Portus-$branch
cp ../../Gemfile* build/Portus-$branch

pushd build/Portus-$branch/
  echo "generate the Gemfile.lock for packaging"
  export BUNDLE_GEMFILE=$PWD/Gemfile
  cp Gemfile.lock Gemfile.lock.orig
  bundle config build.nokogiri --use-system-libraries
  PACKAGING=yes bundle install --retry=3 --no-deployment
  grep "git-review" Gemfile.lock
  if [ $? == 0 ];then
    echo "DEBUG: ohoh something went wrong and you have devel packages"
    diff Gemfile.lock Gemfile.lock.orig
    exit -1
  fi
  echo "get requirements from Gemfile.lock"
  IFS=$'\n' # do not split on spaces
  build_requires=""
  provides=""
  for gem in $(cat Gemfile.lock | grep "    "  | grep "     " -v | sort | uniq);do
    gem_name=$(echo $gem | cut -d" " -f5)
    gem_version=$(echo $gem | cut -d "(" -f2 | cut -d ")" -f1)
    build_requires="$build_requires\nBuildRequires: %{rubygem $gem_name} = $gem_version"
    build_requires="$build_requires\n$(additional_native_build_requirements $gem_name)"
    provides="$provides\nProvides: embedded-rubygem-$gem_name = $gem_version"
  done
popd

echo "create Portus.spec based on Portus.spec.in"
cp Portus.spec.in Portus.spec
sed -e "s/__BRANCH__/$branch/g" -i Portus.spec
sed -e "s/__RUBYGEMS_BUILD_REQUIRES__/$build_requires/g" -i Portus.spec
sed -e "s/__RUBYGEMS_PROVIDES__/$provides/g" -i Portus.spec
sed -e "s/__DATE__/$date/g" -i Portus.spec
sed -e "s/__COMMIT__/$commit/g" -i Portus.spec
sed -e "s/__VERSION__/$version/g" -i Portus.spec
sed -e "s/__CURRENT_YEAR__/$year/g" -i Portus.spec

if [ -f Portus.spec ];then
  echo "Done!"
  exit 0
else
  echo "A problem occured creating the spec file."
  exit -1
fi

