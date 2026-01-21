proxy_status() {
  echo ''
  if [ -z $http_proxy ]; then
    echo "  \033[36m Http-proxy\033[0m :  \033[31moff\033[0m"
  else
    echo "  \033[36m http-proxy\033[0m :  $http_proxy  \033[32m    on\033[0m"
  fi
  if [ -z $https_proxy ]; then
    echo "  \033[36m https-proxy\033[0m:  \033[31moff\033[0m"
  else
    echo "  \033[36m https-proxy\033[0m:  $https_proxy  \033[32m    on\033[0m"
  fi
  if [ -z $all_proxy ]; then
    echo "  \033[36m all-proxy\033[0m  :  \033[31moff\033[0m"
  else
    echo "  \033[36m all-proxy\033[0m  :  $all_proxy  \033[32m  on\033[0m"
  fi
}

proxy_start() {
    export https_proxy=http://myphone:7890 http_proxy=http://myphone:7890 all_proxy=socks5://myphone:7890
    proxy_status
}

proxy_stop() {
    unset https_proxy
    unset http_proxy
    unset all_proxy
    proxy_status
}
