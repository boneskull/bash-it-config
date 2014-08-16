cite about-plugin _about _param _group
about-plugin "Manages your personal bash-it configuration"

CONFIG_PATH="${BASH_IT}/.config"
GIT="/usr/bin/env git"
CWD=`pwd`

_config-read-git-url()
{
  _about "reads a Git repo URL/path from stdin"
  _group "config"
  while true; do
    read -e -p "Enter URL/path of git repository for config: " GIT_URL
    [[ -n ${GIT_URL} ]] && break; 
  done
  echo ${GIT_URL}
}

_config-write()
{
  _about "writes a config file"
  _param "1: config file to write to"
  _param "2..: array of filenames to write to config file"
  _group "config"
  local FILEPATH=${1}
  shift  
  printf "%s\n" $@ > ${FILEPATH}
}

_config-make-config-file()
{
  _about "builds & writes a config file"
  _param "1: source directory, presumably full of symlinks"
  _param "2: destination config file"
  _group "config"
  local SOURCE_DIR=$1
  local DEST_FILE=$2
  local -a FILES
  for FILE in "${BASH_IT}/${SOURCE_DIR}/enabled/*.bash"; do
    FILES=(${FILES[@]} `basename ${FILE}`);
  done
  [[ ${#FILES[@]} -gt 0 ]] && {
     _config-write "${DEST_FILE}" "${FILES[@]}"
    cd "${CONFIG_PATH}"
    ${GIT} add "${DEST_FILE}"
    cd ${CWD}
  } 
}

_config-load-config-file()
{
  _about "loads a config file and creates symlinks"
  _param "1: source config file"
  _param "2: destination directory"
  _group "config"
  local SOURCE_FILE=$1
  local DEST_DIR=$2
  [[ ! -e ${SOURCE_FILE} ]] && {
    echo "${SOURCE_FILE} not found!"
    exit 1
  }
  [[ ! -d ${DEST_DIR} ]] && {
    echo "${DEST_DIR} not found!"
    exit 1
  }
  for FILE in `find "${DEST_DIR}/enabled" -type l`; do
    rm -f "${FILE}"
  done
  for FILE in `cat ${SOURCE_FILE}`; do
    ln -sf "${DEST_DIR}/available/${FILE}" "${DEST_DIR}/enabled/${FILE}"  
  done
}

save-bash-it () 
{
  about "saves current bash-it configuration to source control"
  group "config"
  local CUSTOM_PATH="${CONFIG_PATH}/custom"
  ${GIT} init "${CONFIG_PATH}" 2>&1 > /dev/null
  _config-make-config-file "aliases" "${CONFIG_PATH}/aliases"
  _config-make-config-file "plugins" "${CONFIG_PATH}/plugins"
  _config-make-config-file "completion" "${CONFIG_PATH}/completion"
  mkdir -p "${CUSTOM_PATH}" 
  
  [[ -d ${BASH_IT}/custom && `ls -A "${BASH_IT}/custom/"` ]] && {
    mv "${BASH_IT}/"custom/* "${CUSTOM_PATH}/" 2>/dev/null      
    rm -rf "${BASH_IT}/custom"
    ln -sf "${CUSTOM_PATH}" "${BASH_IT}/custom"
  }
  
  [[ -f ${HOME}/.bash_profile ]] && {
      mv ${HOME}/.bash_profile ${CONFIG_PATH}/bash_profile
      ln -sf ${CONFIG_PATH}/bash_profile ${HOME}/.bash_profile
  }
  
  cd "${CUSTOM_PATH}"
  ${GIT} add .  
  [[ -z `git remote` ]] && {
    local ORIGIN=`_config-read-git-url`    
    ${GIT} remote add origin "${ORIGIN}"    
  }
  commit-bash-it
  pull-bash-it
  push-bash-it
  cd ${CWD}
}

commit-bash-it() 
{
  about "commits current bash-it configuration to source control"
  group "config"
  cd ${CONFIG_PATH} 
  ${GIT} commit -m "Updates $@"
  cd ${CWD}
}

push-bash-it()
{
  about "pushes current bash-it configuration to remote origin"
  group "config"
  cd ${CONFIG_PATH}
  ${GIT} push origin master
  cd ${CWD}
}

pull-bash-it()
{
  about "pulls (+ rebases) bash-it configuration from remote origin"
  group "config"
  if [[ ! -d ${CONFIG_PATH} ]]; then
    local ORIGIN=`_config-read-git-url`
    ${GIT} clone ${ORIGIN} ${CONFIG_PATH}
  fi
  cd ${CONFIG_PATH}
  ${GIT} pull --rebase origin master 
  cd ${CWD}
}

update-bash-it()
{
  about "pulls bash-it configuration from remote origin and then loads it"
  group "config"
  pull-bash-it
  load-bash-it
}

load-bash-it ()
{
  about "loads stored bash-it configuration; creates symlinks."
  group "config"
  _config-load-config-file "${CONFIG_PATH}/aliases" "${BASH_IT}/aliases"
  _config-load-config-file "${CONFIG_PATH}/plugins" "${BASH_IT}/plugins"
  _config-load-config-file "${CONFIG_PATH}/completion" "${BASH_IT}/completion"  
}