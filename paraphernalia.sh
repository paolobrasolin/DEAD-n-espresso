#!/bin/sh

THIS=`readlink -fn $0`
USER="paolobrasolin"
REPO="test"
ORIG="https://github.com/${USER}/${REPO}.git"
PAGES_BRANCH=$([ ${REPO} = ${USER}.github.io ] && echo master || echo gh-pages)

case ${1} in
  pull)
    case ${2} in
      source|"")
        git checkout source
        git pull ${ORIG} source
        ;;
      pages)
        cd _site
        git checkout ${PAGES_BRANCH}
        git pull ${ORIG} ${PAGES_BRANCH}
        cd ..
        ;;
      *)
    esac
    ;;
  push)
    case ${2} in
      source)
        git checkout source
        git add -all
        git pull "https://github.com/${3}/${4}.git" source
        git push "https://github.com/${3}/${4}.git" source
        ;;
      pages)
        PAGES_BRANCH=$([ ${4} = ${3}.github.io ] && echo master || echo gh-pages)
        cd _site
        git checkout ${PAGES_BRANCH}
        git pull "https://github.com/${3}/${4}.git" ${PAGES_BRANCH}
        git push "https://github.com/${3}/${4}.git" ${PAGES_BRANCH}
        cd ..
        ;;
      *)
    esac

#    sh paraphernalia pull
#    git add --all
#    git commit
#    git push "https://github.com/${NAME}/${NAME}.github.com.git" source
#    ;;

#  authorize_token) # user scopes
#    curl -u ${2} -d "{\"scopes\":${3}}" https://api.github.com/authorizations
#    ;;
#  list_tokens) # user
#    curl -u ${2} https://api.github.com/authorizations
#    ;;
#  revoke_token) # user id
#    curl -u ${2} -X DELETE https://api.github.com/authorizations/${3}
#    ;;
#  create_repo)  # user repo
#    JSON=`sh ${THIS} authorize_token ${2} '["repo"]'`
#    TOKEN=`echo ${JSON} | python -c 'import sys,json;print json.loads(sys.stdin.read())["token"]'`
#    ID=`echo ${JSON} | python -c 'import sys,json;print json.loads(sys.stdin.read())["id"]'`
#    curl -X POST -H 'Content-Type: application/x-www-form-urlencoded' -d '{"name": "'${3}'"}' https://api.github.com/user/repos?access_token=${TOKEN}
#    sh ${THIS} revoke_token ${2} ${ID}
#    ;;
#  delete_repo) # user repo
#    JSON=`sh ${THIS} authorize_token ${2} '["delete_repo"]'`
#    TOKEN=`echo ${JSON} | python -c 'import sys,json;print json.loads(sys.stdin.read())["token"]'`
#    ID=`echo ${JSON} | python -c 'import sys,json;print json.loads(sys.stdin.read())["id"]'`
#    curl -H "Authorization: token "${TOKEN} -X DELETE https://api.github.com/repos/${2}/${3}
#    sh ${THIS} revoke_token ${2} ${ID}
#    ;;
#  prepare_repo) # user repo
#    PAGES_BRANCH=$([ ${3} = ${2}.github.io ] && echo master || echo gh-pages)
#    ID=`uuidgen`; mkdir ${ID}; cd ${ID}
#    git init
#    git remote add origin "https://github.com/${2}/${3}.git"
#    git checkout --orphan ${PAGES_BRANCH}
#    git commit --allow-empty -m "first pages commit"
#    git push origin ${PAGES_BRANCH}
#    git checkout --orphan source
#    git submodule add "https://github.com/${2}/${3}.git" _site
#    git add --all
#    git commit -m "first source commit"
#    git push origin source
#    cd ..; rm -rf ${ID}
#    ;;
  *)
esac
